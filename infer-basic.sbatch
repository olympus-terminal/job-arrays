#!/bin/bash

#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-2
#SBATCH --mem=40G
#SBATCH --time=48:00:00
#SBATCH -p nvidia
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=20


LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p filelist.txt)
echo "$LINE"

cleaned=$(echo "$LINE" | tr -dc '[:alnum:]')
echo "$cleaned"

#PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True && python infer-batch6.py /scratch/AI/Pythia-12B-QLORA/output/checkpoint-26750 $LINE >> eval-results-c-Pythia-26750-"$LINE"

python inference_siamese_esm1.py --model_path /scratch/AI/EVALs/PPIs/siamese_esm_model_1epoch_20Frzn.pth --input_file $LINE --output_file out_ppi/"$cleaned"-out.csv --max_length 1024 --device cuda
