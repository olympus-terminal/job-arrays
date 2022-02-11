#!/bin/bash

for f in *blastp.txt ; do echo "$f" >> blast-results.txt; done
mkdir slurm-logs
rm slurm-logs/*
echo "ready for extract_tally-contam_hits-accQ.sbatch deployment"
