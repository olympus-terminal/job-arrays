# SLURM Auto-Resubmission & Retry Patterns

Patterns for long-running GPU array jobs that exceed walltime limits.
Battle-tested on Jubail HPC processing 37,000+ papers across 14 GPU workers.

---

## The Problem

Many HPC workloads take longer than the maximum walltime allows. A single array
task may need to process thousands of items, each taking 20-60 minutes. At 96h
walltime, you'll process ~100-300 items before SLURM kills the job — leaving
thousands unfinished.

Manual resubmission doesn't scale. You need jobs that:

1. Detect when walltime is approaching
2. Stop cleanly (finish the current item, don't corrupt output)
3. Resubmit themselves to continue where they left off
4. Handle failures without breaking the resubmission chain

---

## Pattern 1: USR1 Signal + Flag (Recommended)

SLURM sends a signal before killing the job. Catch it, set a flag, and let the
main loop exit gracefully. **Use USR1, not SIGTERM** — SIGTERM interacts badly
with `set -euo pipefail` and kills child processes.

### SBATCH Header

```bash
#SBATCH --signal=B:USR1@300
```

- `B:` = signal the batch shell (not child processes)
- `USR1` = won't kill running children
- `@300` = send 300 seconds (5 min) before walltime expires

### Signal Handler (top of script, before any work)

```bash
RESUBMIT_FLAG=0
resubmit_handler() {
    echo "[w${SLURM_ARRAY_TASK_ID}] SIGUSR1 — wall time approaching, will resubmit"
    RESUBMIT_FLAG=1
}
trap resubmit_handler USR1
```

### Main Loop Check

```bash
while IFS= read -r ITEM; do
    [[ -z "$ITEM" ]] && continue

    if [[ "$RESUBMIT_FLAG" -eq 1 ]]; then
        echo "[w${WORKER_ID}] stopping loop for clean resubmit"
        break
    fi

    # ... process $ITEM ...
done <<< "$ITEM_LIST"
```

### Cleanup + Resubmit

```bash
SCRIPT_PATH="$PROJECT_ROOT/my_job.sbatch"
cleanup() {
    # Kill any services you started
    for p in "$SERVICE_PID1" "$SERVICE_PID2"; do
        [[ -n "$p" ]] && kill -TERM "$p" 2>/dev/null || true
    done
    sleep 5
    for p in "$SERVICE_PID1" "$SERVICE_PID2"; do
        [[ -n "$p" ]] && kill -KILL "$p" 2>/dev/null || true
    done

    if [[ "$RESUBMIT_FLAG" -eq 1 ]]; then
        REMAINING=$(count_remaining_items)
        if [[ "$REMAINING" != "0" ]]; then
            NEW_JOB=$(sbatch --parsable --array="${WORKER_ID}" "$SCRIPT_PATH" 2>&1)
            echo "[w${WORKER_ID}] resubmitted as job $NEW_JOB ($REMAINING remaining)"
        else
            echo "[w${WORKER_ID}] all items complete, no resubmit needed"
        fi
    fi
}
trap cleanup EXIT SIGTERM SIGINT
```

---

## Why USR1, Not SIGTERM

**SIGTERM + `set -euo pipefail` = broken resubmission.**

When SLURM sends SIGTERM to the batch shell:

1. Bash forwards SIGTERM to the foreground child process (your python script)
2. The child dies with non-zero exit
3. `set -e` triggers immediate exit of the shell
4. The trap handler may never run, or runs with `RESUBMIT_FLAG` still at 0
5. The resubmission chain dies silently

USR1 has none of these problems:

1. USR1 does not kill children — they keep running
2. The handler sets the flag
3. The main loop checks the flag before the next iteration
4. The current item finishes normally
5. Cleanup runs with `RESUBMIT_FLAG=1`, resubmission succeeds

---

## Why Not `SLURM_JOB_SCRIPT`

Never use `SELF_SCRIPT="${SLURM_JOB_SCRIPT:-$0}"` for resubmission.

SLURM copies your script to a spool directory (`/var/spool/slurmd/...`) for
execution. `SLURM_JOB_SCRIPT` points to that temporary copy. When the job ends,
the spool copy may be cleaned up. Your resubmitted job then tries to read a
nonexistent file and fails.

**Always use a hardcoded path to the canonical script location:**

```bash
SCRIPT_PATH="$PROJECT_ROOT/my_job.sbatch"
# ... later, in cleanup:
sbatch --parsable --array="${WORKER_ID}" "$SCRIPT_PATH"
```

---

## Idempotent Processing

Each resubmitted job re-reads the full manifest but skips already-completed
items. This requires:

### Check Output Before Processing

```bash
OUT_JSON="$RESULTS_DIR/$SHARD/${STEM}.json"

if [[ -f "$OUT_JSON" ]]; then
    SKIPPED=$((SKIPPED + 1))
    continue
fi
```

### Count Remaining (for resubmit decision)

```bash
REMAINING=$(python3 -c "
import json, os, glob
m = json.loads(open('$MANIFEST').read())
assigned = m['assignments'].get('$WORKER_ID', [])
results = set()
for f in glob.glob('$RESULTS_DIR/*/*.json'):
    shard = os.path.basename(os.path.dirname(f))
    stem = os.path.splitext(os.path.basename(f))[0]
    results.add(shard + '/' + stem)
remaining = [p for p in assigned if p not in results]
print(len(remaining))
" 2>/dev/null || echo "unknown")
```

---

## Per-Worker Config Isolation

When running services (databases, inference servers) per array task, each worker
needs isolated state. A critical lesson: **always start from a clean config.**

### The Bug

```bash
# BAD: copy config only on first run, accumulate garbage forever
if [[ ! -f "$CONF_DIR/service.conf" ]]; then
    cp "$BASE_CONF" "$CONF_DIR/service.conf"
fi
```

If anything appends stray lines to the config (environment variable leaks, a
service writing its runtime state back), every subsequent resubmission inherits
the corruption. One invalid line can prevent the service from starting, which
causes a startup failure (not a walltime), which doesn't set the resubmit flag,
which silently kills the entire resubmission chain.

### The Fix

```bash
# GOOD: always start fresh from the canonical config
mkdir -p "$CONF_DIR"
cp "$BASE_CONF" "$CONF_DIR/service.conf"
```

The overhead of copying a config file is negligible against a multi-hour job.

---

## Per-Worker Port Isolation

Multiple array tasks may land on the same node. Services must bind to unique
ports per worker.

```bash
RANDOM_SEED=$((WORKER_ID * 7919 + SLURM_ARRAY_JOB_ID))
RANDOM=$RANDOM_SEED
SERVICE_PORT=$(( 20000 + WORKER_ID * 100 + RANDOM % 50 ))
```

- Deterministic per (worker, job) pair — no collisions between workers
- Different across resubmissions (different `SLURM_ARRAY_JOB_ID`)
- Bind to loopback only: `127.0.0.1:${SERVICE_PORT}`

---

## Progress Tracking

Log each item's outcome to a JSONL file so retry manifests can be generated:

```bash
PROGRESS_FILE="$STATE_DIR/worker_${WORKER_ID}_progress.jsonl"

# On success
echo "{\"paper\":\"$ID\",\"status\":\"ok\",\"elapsed_s\":$ELAPSED,\"ts\":\"$(date -u +%FT%TZ)\"}" >> "$PROGRESS_FILE"

# On failure
echo "{\"paper\":\"$ID\",\"status\":\"failed\",\"elapsed_s\":$ELAPSED,\"ts\":\"$(date -u +%FT%TZ)\"}" >> "$PROGRESS_FILE"

# On missing input
echo "{\"paper\":\"$ID\",\"status\":\"missing\",\"ts\":\"$(date -u +%FT%TZ)\"}" >> "$PROGRESS_FILE"
```

---

## Retry Manifest Generation

After a batch completes, generate a new manifest containing only failed and
never-started items:

```python
# Scan progress files
for pf in state_dir.glob("worker_*_progress.jsonl"):
    for line in pf.open():
        entry = json.loads(line)
        if entry["status"] == "ok":
            ok_count += 1
        elif entry["status"] == "failed":
            failed.append(entry["paper"])

# Find items that were assigned but never attempted
manifest = json.loads(manifest_path.read_text())
all_assigned = set()
for paper_list in manifest["assignments"].values():
    all_assigned.update(paper_list)
never_ran = [p for p in all_assigned if p not in seen]

# Rebalance across workers (greedy heap by item size)
retry_papers = failed + never_ran
```

---

## Multi-Partition Resubmission

When running the same pipeline across different partitions (e.g., general GPU
queue + condo queue), keep the resubmission logic identical but use separate:

- **Manifests** — each partition has its own manifest file with its own worker IDs
- **SCRIPT_PATH** — points to the partition-specific sbatch file
- **Worker ID ranges** — non-overlapping (e.g., 0-11 for nvidia, 12-13 for condo)

```bash
# nvidia partition sbatch
#SBATCH --partition=nvidia
#SBATCH --array=0-11
MANIFEST="$STATE_DIR/manifest_nvidia_retry.json"
SCRIPT_PATH="$PROJECT_ROOT/job_nvidia.sbatch"

# condo partition sbatch
#SBATCH --partition=nvidia
#SBATCH -q a2s2
#SBATCH --array=12-13
#SBATCH --gres=gpu:h200:1
MANIFEST="$STATE_DIR/manifest_condo_retry.json"
SCRIPT_PATH="$PROJECT_ROOT/job_condo.sbatch"
```

---

## Complete Minimal Example

```bash
#!/bin/bash
#SBATCH --job-name=batch-process
#SBATCH --partition=nvidia
#SBATCH --array=0-3
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH --time=96:00:00
#SBATCH --signal=B:USR1@300
#SBATCH --output=logs/batch_%A_%a.out
#SBATCH --error=logs/batch_%A_%a.err

set -euo pipefail

# ---- resubmit signal handler (must be before any work) ----
RESUBMIT_FLAG=0
resubmit_handler() {
    echo "[w${SLURM_ARRAY_TASK_ID}] SIGUSR1 — will resubmit"
    RESUBMIT_FLAG=1
}
trap resubmit_handler USR1

export HOME=/scratch/drn2/newhome
export TMPDIR=/scratch/drn2/tmp
mkdir -p "$TMPDIR"

WORKER_ID=${SLURM_ARRAY_TASK_ID}
PROJECT_ROOT=/scratch/drn2/PROJECTS/MY_PROJECT
RESULTS_DIR="$PROJECT_ROOT/results"
MANIFEST="$PROJECT_ROOT/state/manifest.json"
PROGRESS="$PROJECT_ROOT/state/worker_${WORKER_ID}_progress.jsonl"
SCRIPT_PATH="$PROJECT_ROOT/batch_process.sbatch"

source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/drn2/software/conda-mamba_1

# ---- read assignments ----
ITEM_LIST=$(python3 -c "
import json
m = json.loads(open('$MANIFEST').read())
for item in m['assignments'].get('$WORKER_ID', []):
    print(item)
")

# ---- cleanup + resubmit ----
cleanup() {
    if [[ "$RESUBMIT_FLAG" -eq 1 ]]; then
        REMAINING=$(find "$RESULTS_DIR" -name "*.json" | wc -l)
        # (replace with actual remaining-count logic)
        NEW_JOB=$(sbatch --parsable --array="${WORKER_ID}" "$SCRIPT_PATH" 2>&1)
        echo "[w${WORKER_ID}] resubmitted as $NEW_JOB"
    fi
}
trap cleanup EXIT SIGTERM SIGINT

# ---- main loop ----
while IFS= read -r ITEM; do
    [[ -z "$ITEM" ]] && continue

    if [[ "$RESUBMIT_FLAG" -eq 1 ]]; then
        echo "[w${WORKER_ID}] wall time approaching — stopping"
        break
    fi

    OUT="$RESULTS_DIR/${ITEM}.json"
    [[ -f "$OUT" ]] && continue  # idempotent skip

    echo "[w${WORKER_ID}] processing $ITEM"
    T0=$(date +%s)

    if python3 "$PROJECT_ROOT/process.py" --item "$ITEM" --out "$OUT" 2>&1; then
        DT=$(( $(date +%s) - T0 ))
        echo "{\"item\":\"$ITEM\",\"status\":\"ok\",\"elapsed_s\":$DT,\"ts\":\"$(date -u +%FT%TZ)\"}" >> "$PROGRESS"
    else
        DT=$(( $(date +%s) - T0 ))
        echo "{\"item\":\"$ITEM\",\"status\":\"failed\",\"elapsed_s\":$DT,\"ts\":\"$(date -u +%FT%TZ)\"}" >> "$PROGRESS"
    fi
done <<< "$ITEM_LIST"
```

---

## Failure Modes & Lessons Learned

| Failure | Root Cause | Fix |
|---------|-----------|-----|
| Resubmitted jobs crash on startup | Persistent config files accumulated garbage across resubmissions | Always copy fresh config from canonical source |
| Resubmission chain dies silently | `--signal=B:TERM` + `set -e` — SIGTERM kills child, shell exits before handler runs | Use `--signal=B:USR1` instead |
| `sbatch` fails on resubmit: "file not found" | `SLURM_JOB_SCRIPT` points to cleaned-up spool copy | Use hardcoded `SCRIPT_PATH` |
| Workers on same node collide | Services bind to same default port | Deterministic per-worker port allocation |
| All items re-processed on resubmit | No output-exists check | Check for output file before processing |
| Chain resubmits forever on broken items | Startup failures (exit 2) don't set resubmit flag, but genuine failures do cause infinite retry | Separate startup failures from processing failures; only resubmit on walltime signal |
