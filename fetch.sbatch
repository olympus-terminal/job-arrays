#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-40
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=90GB
#SBATCH --time=12:00:00


###use Prepare_filelist.sh to ready up
LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p filelist.txt)
echo $LINE

#fgrep -f $LINE nr >> full-bact.headers
#sed i.bak 's/>//g' ./"$LINE"

./faSomeRecords nr ./"$LINE"-noChev ./"$LINE"-fetched.fa
