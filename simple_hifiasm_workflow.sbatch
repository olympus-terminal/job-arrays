#!/bin/bash

#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-12
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=90GB
#SBATCH --time=4:00:00

LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p filelist.txt)
echo $LINE

#samtools fastq -0 "$LINE"-raw_reads.fq $LINE
#/scratch/drn2/PROJECTS/GORILLA/ZIP/BAM/hifiasm/hifiasm -o "$LINE".asm -t 12 "$LINE"-raw_reads.fq
#awk '/^S/{print ">"$2;print $3}' $LINE > "${LINE%.gfa}".fa
python /scratch/drn2/software/quast-5.0.2/quast.py "${LINE%.gfa}".fa -o "${LINE%.gfa}"_quast-results
