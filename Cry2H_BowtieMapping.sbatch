#!/bin/bash

#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-6
#SBATCH -n 1
#SBATCH --cpus-per-task=28
#SBATCH --mem=90GB
#SBATCH --time=48:00:00

LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p filelist.txt)
echo $LINE

bowtie2 -x /scratch/drn2/fastq/data/processed/Sarah/Interactome-processing/sequences/fasta-CrY2H-custom_genome/CustomGenome2 -U /scratch/drn2/fastq/data/processed/Sarah/Interactome-processing/sequences/Illumina/"$LINE" -S ./first-bt2-out_"$LINE".sam --local
