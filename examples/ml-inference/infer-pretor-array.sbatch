#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH --mem=80G
#SBATCH --time=24:00:00
#SBATCH -p nvidia
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=10
#SBATCH --array=1-128%16  # Run 128 jobs, 16 at a time

echo "Starting job execution"

# Check if input files exist and are not empty
if [ ! -s filelist.txt ]; then
    echo "Error: filelist.txt not found or is empty"
    exit 1
fi

if [ ! -s tokenized-prompt-dirlist.txt ]; then
    echo "Error: tokenized-prompt-dirlist.txt not found or is empty"
    exit 1
fi

# Calculate total number of jobs and set array size
CHECKPOINTS=$(wc -l < filelist.txt)
PROMPTS=$(wc -l < tokenized-prompt-dirlist.txt)
TOTAL_JOBS=$((CHECKPOINTS * PROMPTS))

echo "Number of checkpoints: $CHECKPOINTS"
echo "Number of prompts: $PROMPTS"
echo "Total jobs: $TOTAL_JOBS"

# Check if SLURM_ARRAY_TASK_ID is set
if [ -z "$SLURM_ARRAY_TASK_ID" ]; then
    echo "Error: SLURM_ARRAY_TASK_ID is not set. Are you running this as an array job?"
    exit 1
fi

echo "Current SLURM_ARRAY_TASK_ID: $SLURM_ARRAY_TASK_ID"

# Calculate which checkpoint and prompt to use for this job
# Ensure indices are never 0
CHECKPOINT_INDEX=$(( (SLURM_ARRAY_TASK_ID - 1) / PROMPTS + 1 ))
PROMPT_INDEX=$(( (SLURM_ARRAY_TASK_ID - 1) % PROMPTS + 1 ))

echo "Calculated CHECKPOINT_INDEX: $CHECKPOINT_INDEX"
echo "Calculated PROMPT_INDEX: $PROMPT_INDEX"

# Get the checkpoint directory and prompt dataset for this job
CHECKPOINT_DIR=$(sed -n "${CHECKPOINT_INDEX}p" filelist.txt)
PROMPT_DATASET=$(sed -n "${PROMPT_INDEX}p" tokenized-prompt-dirlist.txt)

echo "Selected checkpoint directory: $CHECKPOINT_DIR"
echo "Selected prompt dataset: $PROMPT_DATASET"

# Check if we got valid values
if [ -z "$CHECKPOINT_DIR" ]; then
    echo "Error: Failed to get checkpoint directory"
    exit 1
fi

if [ -z "$PROMPT_DATASET" ]; then
    echo "Error: Failed to get prompt dataset"
    exit 1
fi

# Clean the names for use in output files
CLEANED_CHECKPOINT=$(echo "$CHECKPOINT_DIR" | tr -dc '[:alnum:]')
CLEANED_PROMPT=$(echo "$PROMPT_DATASET" | tr -dc '[:alnum:]')

echo "Cleaned checkpoint name: $CLEANED_CHECKPOINT"
echo "Cleaned prompt name: $CLEANED_PROMPT"

# Run the inference script
echo "Running inference script..."
PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True python inference-neo-dirtok.py "$CHECKPOINT_DIR" "$PROMPT_DATASET" ./

# Check if the output file was created and has content
OUTPUT_FILE="eval-results_${CLEANED_CHECKPOINT}_${CLEANED_PROMPT}.txt"
if [ -s "$OUTPUT_FILE" ]; then
    echo "Output file $OUTPUT_FILE created successfully with content"
else
    echo "Warning: Output file $OUTPUT_FILE is empty or was not created"
fi

echo "Job completed"q
