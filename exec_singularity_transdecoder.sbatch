#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 3
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=250GB
#SBATCH --time=8:00:00


###use Prepare_filelist.sh to ready up
LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p filelist.txt)
echo $LINE

#singularity pull docker://trinityrnaseq/transdecoder

#singularity exec -B /scratch/drn2/PROJECTS/GORILLA/Fin-2batchHIFI-plus-ONT/genome-analyses:/data transdecoder_latest.sif TransDecoder.LongOrfs -t /data/"$LINE"

singularity exec -B /scratch/drn2/PROJECTS/GORILLA/Fin-2batchHIFI-plus-ONT/genome-analyses:/data transdecoder_latest.sif TransDecoder.Predict -t /data/"$LINE" --no_refine_starts
