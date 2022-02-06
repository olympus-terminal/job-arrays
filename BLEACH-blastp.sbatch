#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-1999
#SBATCH -n 1
#SBATCH --cpus-per-task=28
#SBATCH --mem=90GB
#SBATCH --time=24:00:00

LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p filelist.txt).
echo $LINE

diamond blastp --db /scratch/drn2/data/db/nr --query $LINE --out diamond_blastp_BLEACH-accQ-nr/"$LINE".diamond.blastp.txt --evalue 0.00000001 --threads 28 -k 5 --outfmt 6 qseqid qlen sseqid sallseqid slen qstart qend sstart send qseq sseq evalue bitscore score length pident nident mismatch positive gapopen gaps ppos qframe btop stitle salltitles qcovhsp qtitle
