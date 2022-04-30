#!/bin/bash

#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-6
#SBATCH -n 1
#SBATCH --cpus-per-task=28
#SBATCH --mem=90GB
#SBATCH --time=48:00:00

LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p filelist.txt)
echo $LINE


###for f in *R1.sam; do echo "$f" >> filelist.txt

echo "counting raw alignments"
cat "${LINE%_R*.sam}"_R1.sam "${LINE%_R*.sam}"_R2.sam | awk '{if($3!~/:/)print $3}' | sort | uniq -c | sort -rn > "$LINE"_raw.alignments.totals;

############PART 2#############
#quality filter reads##########
###############################

#filter_bowtie'd_reads
echo "aligning Fastqs";
cat "${LINE%_R*.sam}"_R1.sam  | awk '/XM:i:[0-2]/ && /NM:i:[0-2]/{if(((($2==0)&&(substr($6,0,2)~/(1|2)S/)&&($6~/[3-9][0-9]M|1[0-9][0-9])M/))||(($2==0)&&(substr($6,0,4)~/[3-9][0-9]M|1[0-9][0-9]M/)))||(($2==16)&&(substr($6,length($6) - 3,length($6))!~/[3-9]S|[1-9][0-9]S|1[0-9][0-9]S/)&&($6~/[3-9][0-9]M|1[0-9][0-9]M/)))print $0}'  | sed '/Yeast\|yeast\|Y2H/d' > "$LINE"_R1.nomismatch.sorted;
cat "${LINE%_R*.sam}"_R2.sam  | awk '/XM:i:[0-2]/ && /NM:i:[0-2]/{if(((($2==0)&&(substr($6,0,2)~/(1|2)S/)&&($6~/[3-9][0-9]M|1[0-9][0-9])M/))||(($2==0)&&(substr($6,0,4)~/[3-9][0-9]M|1[0-9][0-9]M/)))||(($2==16)&&(substr($6,length($6) - 3,length($6))!~/[3-9]S|[1-9][0-9]S|1[0-9][0-9]S/)&&($6~/[3-9][0-9]M|1[0-9][0-9]M/)))print $0}' | sed '/Yeast\|yeast\|Y2H/d' > "$LINE"_R2.nomismatch.sorted;

#join R1 and R2 files
echo "joining R1 and R2";
awk 'NR==FNR {a[$1]=$1" "$2" "$3" "$4" "$6" "$10;next} $1 in a {print a[$1],$2,$3,$4,$6,$10}' "$LINE"_R1.nomismatch.sorted "$LINE"_R2.nomismatch.sorted> "$LINE"_R1R2;
wc -l "$LINE"_R1R2> "$LINE"_R1R2.wc;

####################PART 3##########################
#DNA strandedness and fragment size filter##########
####################################################

echo "finding PPIs based on gene sequences performing fragment analysis";

cat "${LINE%_R*.sam}"_R1.sam | awk -F ":" '{if($1 ~ "@SQ")print ($2" "$3)}' | sort -k1,1n >> "$LINE"_gene.lengths;

sed -i 's/LN //g' "$LINE"_gene.lengths;

awk 'NR==FNR {a[$1]=$2;next}{if(($2==$7)&&(((a[$3]-$4)+(a[$8]-$9)+116)>=220)&&(((a[$3]-$4)+(a[$8]-$9)+116)<=520))print $0}' "$LINE"_gene.lengths "$LINE"_R1R2 > "$LINE"_frag.length.filtered.pairs;

##150-trial-## awk 'NR==FNR {a[$1]=$2;next}{if(($2==$7)&&(((a[$3]-$4)+(a[$8]-$9)+166)>=270)&&(((a[$3]-$4)+(a[$8]-$9)+166)<=570))print $0}' "$LINE"_gene.lengths "$LINE"_R1R2 > "$LINE"_frag.length.filtered.pairs

############PART 4#############
#totaling PPI fragments #######
###############################

echo "totaling reads IDing PPI and AD or DB fusions";

cat frag.length.filtered.pairs| awk '{print $3" "$8}'| awk '{if ($2>$1) print substr($2,0,9)" "substr($1,0,9); else print substr($1,0,9)" "substr($2,0,9)}' |sort -k1,1V -k2,2V | uniq -c | sort -n > "$LINE"_frag.length.filtered.pair_counts.csv;

echo "separating PPIs from AD or DB fusions";
cat "$LINE"_frag.length.filtered.pair_counts.csv | awk '{if(($0!~/AD/)&&($0!~/DB/))print $0}' > "$LINE"_PPI_pairs.csv;

echo "finding clones in PPIs";
awk '{if($3>$8)print $1,$3,$4,$8,$9; else print $1,$8,$9,$3,$4}' "$LINE"_frag.length.filtered.pairs | sort -u -k2,2V -k4,4V -k3,3n -k5,5n | awk '{print $1}' > "$LINE"_R1R2.PPIs.noclones.ids;

echo "removing PPI clones";
awk 'NR==FNR {a[$1]=$1;next} $1 in a {print $3" "$8}' "$LINE"_R1R2.PPIs.noclones.ids "$LINE"_frag.length.filtered.pairs | awk '{if ($2>$1) print substr($2,0,9)" "substr($1,0,9); else print substr($1,0,9)" "substr($2,0,9)}' |sort -k1,1V -k2,2V | uniq -c | sort -n > "$LINE"_R1R2.PPIs.noclones;

echo "separating non-clonal PPIs from fusions";
cat "$LINE"_R1R2.PPIs.noclones | awk '{if(($0!~/AD/)&&($0!~/DB/))print $0}' > "$LINE"_PPI_pairs.noclones.csv;

done
