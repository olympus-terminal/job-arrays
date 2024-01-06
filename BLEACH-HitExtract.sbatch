#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-171
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=90GB
#SBATCH --time=8:00:00


###use Prepare_filelist.sh to ready up
LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p filelist.txt)
echo $LINE

#################################################################################
##get accessions of blastp hits                            ##global
#cut -f 3 $LINE > "$LINE"_hit.accns
#################################################################################

####from total accessions, get contaminants
#LC_ALL=C fgrep -w -f "$LINE"_hit.accns /scratch/drn2/fastq/data/raw/db/ACCNs/bact_accns > "$LINE".bact_hits
#LC_ALL=C fgrep -w -f "$LINE"_hit.accns /scratch/drn2/fastq/data/raw/db/ACCNs/fungal_accns > "$LINE".fungal_hits
#LC_ALL=C fgrep -w -f "$LINE"_hit.accns /scratch/drn2/fastq/data/raw/db/ACCNs/archaea_accns > "$LINE".archaea_hits

#wait 1

#LC_ALL=C fgrep -w -f "$LINE".bact_hits $LINE >> "$LINE".bact_hits.extracted
#LC_ALL=C fgrep -w -f "$LINE".fungal_hits $LINE >> "$LINE".fungal_hits.extracted
#LC_ALL=C fgrep -w -f "$LINE".archaea_hits $LINE >> "$LINE".archaea_hits.extracted

#cut -f 1 "$LINE".bact_hits.extracted >> "$LINE".bact_hits.extracted.headers
#cut -f 1 "$LINE".fungal_hits.extracted >> "$LINE".fungal_hits.extracted.headers
#cut -f 1 "$LINE".archaea_hits.extracted >> "$LINE".archaea_hits.extracted.headers

/scratch/drn2/software/CSE-UCSC-LinuxScripts/faSomeRecords ../"${LINE%.diamond.blastp.txt}" "$LINE".bact_hits.extracted.headers "$LINE".bact_hits.extracted.headers-EX2_b.fa
/scratch/drn2/software/CSE-UCSC-LinuxScripts/faSomeRecords ../"${LINE%.diamond.blastp.txt}" "$LINE".fungal_hits.extracted.headers "$LINE".bact_hits.extracted.headers-EX2_f.fa
/scratch/drn2/software/CSE-UCSC-LinuxScripts/faSomeRecords ../"${LINE%.diamond.blastp.txt}" "$LINE".archaea_hits.extracted.headers "$LINE".bact_hits.extracted.headers-EX2_a.fa
