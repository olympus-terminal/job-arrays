#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-247%20
#SBATCH --mem=40G
#SBATCH --time=4:00:00
#SBATCH -p nvidia
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=20

# Get the total number of lines in filelist-prompts.txt
TOTAL_PROMPTS=$(wc -l < filelist-prompts.txt)

# Calculate the actual array task ID
ACTUAL_ID=$(( (SLURM_ARRAY_TASK_ID - 1) / TOTAL_PROMPTS + 1 ))

# Calculate the prompt index
PROMPT_INDEX=$(( (SLURM_ARRAY_TASK_ID - 1) % TOTAL_PROMPTS + 1 ))

# Get the input file from filelist.txt
LINE=$(sed -n "${ACTUAL_ID}p" filelist.txt)
echo "Processing file: $LINE"

# Get the prompt from filelist-prompts.txt
PROMPT=$(sed -n "${PROMPT_INDEX}p" filelist-prompts.txt)
echo "Using prompt: $PROMPT"

# Clean the filename for output
cleaned=$(echo "$LINE" | tr -dc '[:alnum:]')

# Run the Python script with both inputs
PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True python infer-ByT5tok-attn.py "$LINE" "$PROMPT" >> "${cleaned}_${PROMPT}"
