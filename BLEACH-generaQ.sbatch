#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-94
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=90GB
#SBATCH --time=8:00:00

LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p blast-results.txt)
echo $LINE

##extract query seqs marked as contaminants
LC_ALL=C fgrep -w -f uniq-contam-genera.txt $LINE > "$LINE"-hit.contam-query

##count how many queries were contaminants
cut -f 1 "$LINE"-hit.contam-query | cut -d : -f 2 - | sort - | uniq - | wc -l >> "$LINE"-hit.contam-query-count

##get total number of tORFs with hits
cut -f 1 $LINE | sort - | uniq - | wc -l >> "$LINE"-total-tORFs-w-hits.txt

##find ratio to plot
echo "$LINE" > "$LINE".name
paste "$LINE".name "$LINE"-hit.contam-query-count "$LINE"-total-tORFs-w-hits.txt >> contam-tORF-total.ratio

##get contaminant rTORF names for downstream removal
cut -f 1 "$LINE"-hit.contam-query > "$LINE"-hit.contam-tORF-list.txt

##cleanup
rm "$LINE".name
rm "$LINE"-hit.contam-query
rm "$LINE"-hit.contam-query-count
rm "$LINE"-total-tORFs-w-hits.txt
