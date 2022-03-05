 #!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-141
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=90GB
#SBATCH --time=8:00:00


###use Prepare_filelist.sh to ready up
LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p blast-results.txt)
echo $LINE

#################################################################################
##get accessions of blastp hits                            ##global
cut -f 3 $LINE > "$LINE"_hit.accns
#################################################################################

####from total accessions, get contaminants
LC_ALL=C fgrep -w -f "$LINE"_hit.accns bact_accns > "$LINE".bact_hits
LC_ALL=C fgrep -w -f "$LINE"_hit.accns fungal_accns > "$LINE".fungal_hits
LC_ALL=C fgrep -w -f "$LINE"_hit.accns archaea_accns > "$LINE".archaea_hits

##count how many queries were contaminants
cut -f 1 "$LINE".bact_hits | cut -d : -f 2 - | sort - | uniq - | wc -l >> "$LINE"-hit.contam-query-count.bact
cut -f 1 "$LINE".fungal_hits | cut -d : -f 2 - | sort - | uniq - | wc -l >> "$LINE"-hit.contam-query-count.fung
cut -f 1 "$LINE".archaea_hits | cut -d : -f 2 - | sort - | uniq - | wc -l >> "$LINE"-hit.contam-query-count.arch

#################################################################################
##get total number of tORFs with hits                 ##global
cut -f 1 $LINE | sort - | uniq - | wc -l >> "$LINE"-total-tORFs-w-hits.txt
#################################################################################

##find ratio to plot
echo "$LINE" > "$LINE".name
paste "$LINE".name "$LINE"-hit.contam-query-count.bact "$LINE"-total-tORFs-w-hits.txt >> contam-tORF-total.ratio.bact
paste "$LINE".name "$LINE"-hit.contam-query-count.fung "$LINE"-total-tORFs-w-hits.txt >> contam-tORF-total.ratio.fung
paste "$LINE".name "$LINE"-hit.contam-query-count.arch "$LINE"-total-tORFs-w-hits.txt >> contam-tORF-total.ratio.arch

##get contaminant query seqs
LC_ALL=C fgrep -w -f "$LINE".bact_hits $LINE >> "$LINE"-hit.contam-query.bact
LC_ALL=C fgrep -w -f "$LINE".fungal_hits $LINE >> "$LINE"-hit.contam-query.fung
LC_ALL=C fgrep -w -f "$LINE".archaea_hits $LINE >> "$LINE"-hit.contam-query.arch

cut -f 1 "$LINE"-hit.contam-query.bact >> "$LINE"-hit.contam-query-name.bact
cut -f 1 "$LINE"-hit.contam-query.fung >> "$LINE"-hit.contam-query-name.fung
cut -f 1 "$LINE"-hit.contam-query.arch >> "$LINE"-hit.contam-query-name.arch

cp "$LINE"-hit.contam-query-name.bact /scratch/drn2/data/MACROALGAE/snap/
cp "$LINE"-hit.contam-query-name.fung /scratch/drn2/data/MACROALGAE/snap/
cp "$LINE"-hit.contam-query-name.arch /scratch/drn2/data/MACROALGAE/snap/

#######cleanup

rm "$LINE".bact_hits
rm "$LINE".fungal_hits
rm "$LINE".archaea_hits

rm "$LINE"-hit.contam-query-count.bact
rm "$LINE"-hit.contam-query-count.fung
rm "$LINE"-hit.contam-query-count.arch

rm "$LINE"-hit.contam-query.bact
rm "$LINE"-hit.contam-query.fung
rm "$LINE"-hit.contam-query.arch

cd /scratch/drn2/data/MACROALGAE/snap

/scratch/drn2/software/faSomeRecords "${LINE%.diamond.blastp.txt}" -exclude "$LINE"-hit.contam-query-name.bact "${LINE%.diamond.blastp.txt}"_LongBLEACHd
