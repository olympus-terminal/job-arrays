#!/bin/bash

#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-4
#SBATCH -n 1
#SBATCH --cpus-per-task=12
#SBATCH --mem=90GB
#SBATCH --time=24:00:00

LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p filelist.txt)
echo $LINE

#samtools fastq -0 "$LINE"-raw_reads.fq $LINE
hifiasm -o "$LINE".asm -t 12 "$LINE"-raw_reads.fq
