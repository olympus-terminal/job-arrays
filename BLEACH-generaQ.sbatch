#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-141
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=90GB
#SBATCH --time=8:00:00

LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p blast-results.txt)
echo $LINE

##extract query seqs marked as contaminants
LC_ALL=C fgrep -w -f gen_class-Fungi.list-only_species.txt.uniq $LINE > "$LINE"-hit.contam-query.f

##count how many queries were contaminants
cut -f 1 "$LINE"-hit.contam-query.f | cut -d : -f 2 - | sort - | uniq - | wc -l >> "$LINE"-hit.contam-query-count.f

##get total number of tORFs with hits
cut -f 1 $LINE | sort - | uniq - | wc -l >> "$LINE"-total-tORFs-w-hits.txt.f

##find ratio to plot
echo "$LINE" > "$LINE".name.f
paste "$LINE".name.f "$LINE"-hit.contam-query-count.f "$LINE"-total-tORFs-w-hits.txt.f >> contam-tORF-total.ratio.f

##get contaminant rTORF names for downstream removal
cut -f 1 "$LINE"-hit.contam-query.f > "$LINE"-hit.contam-tORF-list.txt.f

##cleanup
rm "$LINE".name.f
rm "$LINE"-hit.contam-query.f
rm "$LINE"-hit.contam-query-count.f
rm "$LINE"-total-tORFs-w-hits.txt.f

##extract query seqs marked as contaminants
LC_ALL=C fgrep -w -f gen_class-Bacteria.list-only_species.txt.uniq $LINE > "$LINE"-hit.contam-query.b

##count how many queries were contaminants
cut -f 1 "$LINE"-hit.contam-query.b | cut -d : -f 2 - | sort - | uniq - | wc -l >> "$LINE"-hit.contam-query-count.b

##get total number of tORFs with hits
cut -f 1 $LINE | sort - | uniq - | wc -l >> "$LINE"-total-tORFs-w-hits.txt.b

##find ratio to plot
echo "$LINE" > "$LINE".name.b
paste "$LINE".name.b "$LINE"-hit.contam-query-count.b "$LINE"-total-tORFs-w-hits.txt.b >> contam-tORF-total.ratio.b

##get contaminant rTORF names for downstream removal
cut -f 1 "$LINE"-hit.contam-query.b > "$LINE"-hit.contam-tORF-list.txt.b

##cleanup
rm "$LINE".name.b
rm "$LINE"-hit.contam-query.b
rm "$LINE"-hit.contam-query-count.b
rm "$LINE"-total-tORFs-w-hits.txt.b

cat "$LINE"-hit.contam-tORF-list.txt.f "$LINE"-hit.contam-tORF-list.txt.b >> "$LINE"-BLEACH-FunBact-contam.list
rm "$LINE"-hit.contam-tORF-list.txt.f
rm "$LINE"-hit.contam-tORF-list.txt.b
