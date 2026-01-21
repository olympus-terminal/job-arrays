# JUBAIL HPC - ONE-PAGE QUICK REFERENCE

**NYU Abu Dhabi HPC | User: drn2**

---

## 🚨 GOLDEN RULES

1. **NEVER use `/home/drn2`** → Always use `/scratch/drn2/newhome/`
2. **ALWAYS detect environment** → HPC paths ≠ local paths

---

## 🏗️ Directory Structure

```
/scratch/drn2/
├── newhome/                 # HOME (miniconda, .bashrc, .ssh)
├── software/conda-mamba_1/  # ML/AI conda environment
├── tmp/                     # TMPDIR for jobs
└── PROJECTS/                # All projects here
    └── YOUR_PROJECT/
```

---

## 🔑 Essential Aliases (Login Node)

```bash
ho      # export HOME=/scratch/drn2/newhome
mamba   # Load modules + activate ML conda env
```

**Run both before any work!**

---

## 🐍 Python Environment Detection Template

```python
import socket
hostname = socket.gethostname()
if 'cn' in hostname or 'gpu' in hostname or 'jubail' in hostname:
    BASE_DIR = "/scratch/drn2/PROJECTS/YOUR_PROJECT"
else:
    BASE_DIR = "/media/drn2/External/YOUR_PROJECT"
```

---

## 🖥️ SLURM Script Template

```bash
#!/bin/bash
#SBATCH --partition=compute    # or 'nvidia' for GPU
#SBATCH --cpus-per-task=28
#SBATCH --mem=90G
#SBATCH --time=48:00:00
#SBATCH --output=logs/slurm_%j.out
#SBATCH --error=logs/slurm_%j.err

# CRITICAL ENVIRONMENT SETUP
export HOME=/scratch/drn2/newhome
export TMPDIR=/scratch/drn2/tmp
export PYTHONUSERBASE=/scratch/drn2/newhome/.local
mkdir -p $TMPDIR
unset NETWORKX_BACKEND_CONFIG
unset NX_BACKEND_CONFIG

# Load modules
module load gcc/13.2.0
# module load cuda/12.2.0  # Uncomment for GPU

# Activate conda
source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/drn2/software/conda-mamba_1

# Run script
cd /scratch/drn2/PROJECTS/YOUR_PROJECT
python scripts/your_script.py
```

---

## 📊 Job Commands

```bash
# Submit
sbatch script.sbatch
sbatch --array=1-10 script.sbatch
sbatch --dependency=afterok:12345 script.sbatch

# Monitor
squeue -u drn2
tail -f logs/slurm_12345.out
sacct -j 12345

# Cancel
scancel 12345
scancel -u drn2  # all jobs
```

---

## 🔍 Partitions

| Partition | Use | GPU |
|-----------|-----|-----|
| `nvidia` | GPU jobs | ✅ V100/A100/H100 |
| `compute` | CPU parallel | ❌ |

---

## 🔄 File Transfer

```bash
# Local → HPC
rsync -Pvrt local_dir/ drn2@jubail.abudhabi.nyu.edu:/scratch/drn2/PROJECTS/project/

# HPC → Local
rsync -Pvrt drn2@jubail.abudhabi.nyu.edu:/scratch/drn2/PROJECTS/project/ local_dir/
```

---

## 🧪 Testing Workflow

1. **Test locally first**
2. **Test interactively on HPC:**
   ```bash
   srun --pty --partition=compute --cpus-per-task=4 --mem=16G --time=1:00:00 bash
   export HOME=/scratch/drn2/newhome
   source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh
   conda activate /scratch/drn2/software/conda-mamba_1
   ```
3. **Submit batch job**
4. **Monitor carefully**

---

## ✅ Pre-Submission Checklist

- [ ] Python script has environment detection
- [ ] SLURM script sets `HOME=/scratch/drn2/newhome`
- [ ] Conda sourced from newhome
- [ ] Correct partition (nvidia/compute)
- [ ] Log directories exist: `mkdir -p logs results figures`
- [ ] Files rsynced to HPC

---

## 🚨 Common Errors & Fixes

| Error | Fix |
|-------|-----|
| `/home/drn2` not found | `export HOME=/scratch/drn2/newhome` |
| FileNotFoundError | Add environment detection to Python |
| ModuleNotFoundError | Install package in conda env |
| conda not found | Source conda.sh before activate |
| DependencyNeverSatisfied | Check previous job logs |

---

## 📞 Help

**Full Guide:** `JUBAIL_BEST_PRACTICES.md`
**HPC Support:** nyuad.it.help@nyu.edu
