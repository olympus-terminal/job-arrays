#!/bin/bash

#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-12
#SBATCH -n 1
#SBATCH --cpus-per-task=7
#SBATCH --mem=90GB
#SBATCH --time=24:00:00

i=$(sed -n "$SLURM_ARRAY_TASK_ID"p ilist.txt)
echo $i

#samtools fastq -0 "$LINE"-raw_reads.fq $LINE

hifiasm -o ./k-mer-cycle/gorilla-kmer-"$i".asm -t 7 gorilla.fq -k "$i"
