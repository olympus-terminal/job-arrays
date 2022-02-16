#!/bin/bash

if [[ -f blast-results.txt ]]
then
    rm blast-results.txt
fi


if [[ ! -f blast-results.txt ]]
then
    for f in *blastp.txt ; do echo "$f" >> blast-results.txt; done
fi

echo "There are"
wc -l blast-results.txt
echo "jobs to submit"


if [[ -d slurm-logs ]]
then
    rm slurm-logs/*
    echo "error logs and outputs will go to slurm-logs"
fi

if [[ ! -d slurm-logs ]]

then
   echo "error logs and outputs will go to slurm-logs"
   mkdir slurm-logs
fi

echo "ready for extract_tally-contam_hits-accQ.sbatch deployment"
