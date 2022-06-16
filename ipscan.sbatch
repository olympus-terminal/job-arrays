#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-137
#SBATCH -n 1
#SBATCH --cpus-per-task=2
#SBATCH --mem=90GB
#SBATCH --time=96:00:00

LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p filelist.txt)
echo $LINE

module load all
module load gencore/2
module load interproscan/5.55_88.0
interproscan.sh -i $LINE --iprlookup --goterms -b "$LINE"_IPscanOut
