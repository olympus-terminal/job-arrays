#!/bin/bash

# Check if a job ID is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <job_id>"
    exit 1
fi

job_id=$1

# Get job information from SLURM
job_info=$(sacct -j $job_id -o JobID,JobName,User,Partition,State,ExitCode,WorkDir --parsable2)

# Extract individual fields from the job information
job_id=$(echo "$job_info" | awk -F'|' '{print $1}')
job_name=$(echo "$job_info" | awk -F'|' '{print $2}')
user=$(echo "$job_info" | awk -F'|' '{print $3}')
partition=$(echo "$job_info" | awk -F'|' '{print $4}')
state=$(echo "$job_info" | awk -F'|' '{print $5}')
exit_code=$(echo "$job_info" | awk -F'|' '{print $6}')
work_dir=$(echo "$job_info" | awk -F'|' '{print $7}' | tr -d '\n' | sed 's/^WorkDir//') # Remove 'WorkDir' prefix

# Print job information
echo "Job ID: $job_id"
echo "Job Name: $job_name"
echo "User: $user"
echo "Partition: $partition"
echo "State: $state"
echo "Exit Code: $exit_code"
echo "Work Directory: $work_dir"

# Change to the working directory
cd "$work_dir" || exit

# Find the latest .sbatch file in the working directory
latest_sbatch_file=$(ls -t *.sbatch 2>/dev/null | head -n 1)

if [ -n "$latest_sbatch_file" ]; then
    echo "Job Script File Contents ($latest_sbatch_file):"
    cat "$latest_sbatch_file"
else
    echo "No .sbatch file found in the working directory."
fi
