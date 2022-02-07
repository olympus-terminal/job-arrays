#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-1999
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=90GB
#SBATCH --time=8:00:00

LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p blast-result-filelist.txt)
echo $LINE

##get list of accessions hit by blastp
cut -f 3 $LINE >"$LINE"-hit.acc

##look for those accessions in the list of all bacterial accessions in nr
LC_ALL=C fgrep -w -f "$LINE"-hit.acc /scratch/drn2/data/MACROALGAE/snap/accQ/bacteria-accession-list-2021-ashish.txt-protein_id.list >> "$LINE"-hit.contam

##extract query seqs marked as contaminants
LC_ALL=C fgrep -w -f "$LINE"-hit.contam $LINE > "$LINE"-hit.contam-query

##count how many queries were contaminants
cut -f 1 "$LINE"-hit.contam-query | sort - | uniq - | wc -l >> "$LINE"-hit.contam-query-count

##get total number of tORFs with hits
cut -f 1 $LINE | sort - | uniq - | wc -l >> "$LINE"-total-tORFs-w-hits.txt

##find ratio to plot
echo "$LINE" > "$LINE".name
paste "$LINE".name "$LINE"-hit.contam-query-count "$LINE"-total-tORFs-w-hits.txt >> contam-tORF-total.ratio

##get contaminant rTORF names for downstream removal
cut -f 1 "$LINE"-hit.contam-query > "$LINE"-hit.contam-tORF-list.txt

##cleanup
rm "$LINE"-hit.acc
rm "$LINE".name
rm "$LINE"-hit.contam
