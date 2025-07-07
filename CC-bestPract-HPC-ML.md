# Claude Best Practices for HPC/ML Workflows

## Core Principles

### 1. Self-Contained Scripts
- Define ALL variables within scripts, not as command-line arguments
- Makes jobs reproducible and easier to track
- Example: SLURM scripts should have paths hardcoded

### 2. Array Indexing
- Always use 0-based indexing for consistency with Python/Bash/C
- SLURM arrays: `--array=0-53` for 54 items (not 1-54)
- Direct array access: `${ARRAY[$SLURM_ARRAY_TASK_ID]}`

### 3. Modular Design with Modulo Arithmetic
```bash
# For flexible array processing
CHECKPOINT_INDEX=$(( $SLURM_ARRAY_TASK_ID % $NUM_CHECKPOINTS ))
RUN_NUMBER=$(( $SLURM_ARRAY_TASK_ID / $NUM_CHECKPOINTS ))
```

### 4. File Transfer Best Practices
- Use `rsync -rtvzP` as default (no permission issues between systems)
- Add `--delete` only when exact mirroring is needed
- Avoid `-a` when transferring between different users/systems

## Project Organization

### 1. Directory Structure
```
project/
├── scripts/           # SLURM and utility scripts
├── src/              # Python source code
├── checkpoints/      # Model checkpoints
├── results/          # Output CSVs and logs
└── data/            # Training/test data
```

### 2. Naming Conventions
- SLURM scripts: `{task}_{type}.slurm` (e.g., `evaluate_checkpoints_self_contained.slurm`)
- Output files: Include task ID and descriptive info
- Use underscores, not hyphens, for consistency

### 3. Script Evolution
- Keep only the final, working version
- Remove prototypes to avoid confusion
- Use descriptive names that indicate functionality

## SLURM Best Practices

### 1. Job Arrays
```bash
#SBATCH --array=0-N%M  # N tasks, M concurrent
```
- Always specify concurrent limit (e.g., %10)
- Use array task ID for deterministic processing
- Output files should include `%A_%a` for job and task IDs

### 2. GPU Jobs
```bash
#SBATCH --partition=nvidia
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
```

### 3. Error Handling
```bash
# Check if required files exist
if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

# Validate array task ID
if [ -z "$SLURM_ARRAY_TASK_ID" ]; then
    echo "Error: Not running as array job"
    exit 1
fi
```

## Python/ML Practices

### 1. Checkpoint Detection
```python
# Check if directory itself is a checkpoint first
if path.is_dir() and 'adapter_model.safetensors' in [f.name for f in path.iterdir()]:
    return [str(path)]
```

### 2. Memory Management
```python
# Clean up after each model evaluation
del model
torch.cuda.empty_cache()
```

### 3. Comprehensive Metrics
- Always include: accuracy, precision, recall, F1, AUC, MCC
- Save confusion matrix details (TP, TN, FP, FN)
- Track source paths and experiment metadata

## Data Management

### 1. File Lists
- Use simple text files for lists (e.g., `checkpoint_dirs.txt`)
- One path per line, no trailing spaces
- Use absolute paths for clarity

### 2. CSV Output
- Include all relevant metadata (paths, parameters, timestamps)
- Use consistent column ordering
- Design for easy merging from parallel jobs

### 3. Cleanup Commands
```bash
# Safe aliases for common operations
alias cj='rm -f checkpoint_eval_*.out checkpoint_eval_*.err'
```

## Debugging Workflow

### 1. Test First
```bash
# Dry run
find . -name 'pattern' ! -name 'exclude'
# Then add -delete

# Check array indexing
echo "Task $TASK_ID → Line $((TASK_ID + 1))"
```

### 2. Logging
- Always log key variables at start
- Include timestamps
- Show progress for long operations

### 3. Common Issues
- Empty results → Check if paths are already checkpoints
- Array index errors → Ensure 0-based indexing
- Permission errors → Use -rtv instead of -a for rsync

## Advanced Patterns

### 1. Multiple Runs per Item
```bash
RUNS_PER_ITEM=2
if [ $RUN_NUMBER -ge $RUNS_PER_ITEM ]; then
    exit 0
fi
SEED=$(( $BASE_SEED + $SLURM_ARRAY_TASK_ID ))
```

### 2. Dynamic Array Sizing
```bash
NUM_ITEMS=$(wc -l < "$LIST_FILE")
ARRAY_END=$((NUM_ITEMS - 1))
sbatch --array=0-${ARRAY_END} script.slurm
```

### 3. Result Aggregation
```python
# Merge array job outputs
dfs = [pd.read_csv(f) for f in glob.glob('eval_*.csv')]
merged = pd.concat(dfs, ignore_index=True)
```

## Key Commands Reference

```bash
# Submit array job for 54 checkpoints
sbatch evaluate_checkpoints_self_contained.slurm

# Check job status
squeue -u $USER

# Merge results
python merge_evaluation_results.py

# Sync to HPC (no permissions)
rsync -rtvzP local/ hpc:remote/

# Clean job outputs
cj  # alias for rm checkpoint_eval_*.{out,err}
```

## Philosophy
- Explicit > Implicit (hardcode paths in scripts)
- Simple > Complex (use existing tools well)
- Reproducible > Flexible (self-contained jobs)
- 0-indexed > 1-indexed (consistency across systems
