#!/bin/bash

for f in *blastp.txt ; do echo "$f" >> blast-result-filelist.txt; done
mkdir slurm-logs
rm slurm-logs/*
wc -l blast-result-filelist.txt
echo “adjust array count with number of lines of blast-result-filelist.txt”
echo "ready for extract_tally-contam_hits-accQ.sbatch deployment"
