#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-8
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=21GB
#SBATCH --time=4:00:00


###use Prepare_filelist.sh to ready up
LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p output.txt)
echo $LINE

cleaned=$(echo "$LINE" | tr -dc '[:alpha:]')

cp -r "$LINE"/output/checkpoint-25000 /scratch/drn2/PROJECTS/AI/EVALs/Jun16thTestingChkpts/"$cleaned"_checkpoint-25000

cp -r "$LINE"/output/checkpoint-50000 /scratch/drn2/PROJECTS/AI/EVALs/Jun16thTestingChkpts/"$cleaned"_checkpoint-50000

cp -r "$LINE"/output/checkpoint-100000 /scratch/drn2/PROJECTS/AI/EVALs/Jun16thTestingChkpts/"$cleaned"_checkpoint-100000
