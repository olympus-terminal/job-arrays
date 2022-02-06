#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=90GB
#SBATCH --time=4:00:00

LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p blast-result-filelist.txt)
echo $LINE


##get list of accessions hit by blastp

cut -f 3 $LINE >"$LINE"-hit.acc

##look for those accessions in the list of all bacterial accessions in nr

LC_ALL=C fgrep -w -f "$LINE"-hit.acc /scratch/drn2/data/MACROALGAE/snap/accQ/bacteria-accession-list-2021-ashish.txt-protein_id.list >> "$LINE"-hit.contam


##tally how many contaminant hits

wc -l "$LINE"-hit.contam >> bact-accQ-contam-counts.txt


##extract query seqs marked as contaminants

grep -w -f "$LINE"-hit.contam $LINE > "$LINE"-hit.contam-query

##count how many queries were contaminants

cut -f 1 "$LINE"-hit.contam-query | sort - | uniq - | wc -l >> "$LINE"-hit.contam-query-count

echo "$LINE" > "$LINE"-hit.name

cat  "$LINE"-hit.name "$LINE"-hit.contam-query-count >> bact-accQ-contam-tORF-counts.txt


##get total number of tORFs with hits

cut -f 1 "$LINE"-hit.contam-query > "$LINE"-hit.contam-cds-list.txt

cut -f 1 $LINE | sort - | uniq - | wc -l >> "$LINE"-total-tORFs-w-hits.txt


##cleanup

rm "$LINE"-hit.name

rm "$LINE"-hit.counts

rm "$LINE"-hit.contam

rm "$LINE"-hit.acc
