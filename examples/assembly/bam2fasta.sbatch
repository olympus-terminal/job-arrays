#!/bin/bash

#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-4
#SBATCH -n 1
#SBATCH --cpus-per-task=1
#SBATCH --mem=90GB
#SBATCH --time=24:00:00

LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p filelist.txt)
echo $LINE

samtools fasta -0 "$LINE"-raw_reads.fa $LINE
