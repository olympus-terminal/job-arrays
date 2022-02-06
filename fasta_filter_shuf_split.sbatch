#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-15
#SBATCH -n 1
#SBATCH --cpus-per-task=2
#SBATCH --mem=36GB
#SBATCH --time=8:00:00

LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p fa-files.txt)
echo $LINE

sed -i 's/\./_/g' $LINE;
sed -i 's/ /_/g' $LINE;
sed -i 's/,/_/g' $LINE;
sed -i 's/)/_/g' $LINE;
sed -i 's/(/_/g' $LINE;
sed -i 's/:/_/g' $LINE;

cat $LINE | ./seq-shuf.pl > "$LINE"-shufout;

./faSplit about "$LINE"-shufout 10000000 "$LINE";

rm $LINE
