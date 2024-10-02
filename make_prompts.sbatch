#!/bin/bash

#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-3
#SBATCH -n 1
#SBATCH --cpus-per-task=2
#SBATCH --mem=90GB
#SBATCH --time=4:00:00


###use Prepare_filelist.sh to ready up
LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p filelist-thermo.txt)
echo $LINE
cleaned=$(echo "$LINE" | tr -dc '[:alnum:]')


python fasta2prompt-c3o.py $LINE >> ./"$cleaned"-prompts
