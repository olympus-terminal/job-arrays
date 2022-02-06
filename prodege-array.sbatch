#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-324
#SBATCH -n 1
#SBATCH --cpus-per-task=12
#SBATCH --mem=90GB
#SBATCH --time=12:00:00

LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p config-files.txt)
echo $LINE

singularity exec /scratch/drn2/software/jgi-prodege/prodege_latest.sif /scratch/drn2/software/jgi-prodege/bin/prodege.sh $LINE
