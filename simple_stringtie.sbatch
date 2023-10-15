#!/bin/bash
#SBATCH -o slurm-logs/arrayJob_%A_%a.out
#SBATCH -e slurm-logs/arrayJob_%A_%a.err
#SBATCH -a 1-6
#SBATCH -n 1
#SBATCH --cpus-per-task=28
#SBATCH --mem=90GB
#SBATCH --time=4:00:00

###use Prepare_filelist.sh to ready up - file names are read 1 only
LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p filelist.txt)
echo $LINE

##/scratch/drn2/software/hisat2/hisat2 -p 28 -x CFhisat2index -1 $LINE -2 "${LINE%read1.fastq.gz}"read2.fastq.gz -S "${LINE%read1.fastq.gz}"_Hisat2Alignment.sam --met-file "${LINE%read1.fastq.gz}"_metfile.txt --su$
##samtools sort -o ./bt2-SAM/"${LINE%read1.fastq.gz}".sorted.bam ./bt2-SAM/"${LINE%read1.fastq.gz}".sam

##/scratch/drn2/software/stringtie-2.2.1.Linux_x86_64/stringtie ./bt2-SAM/"${LINE%read1.fastq.gz}".sorted.bam >> ./stringtie_output/"${LINE%read1.fastq.gz}"_stringtie-out.gtf

/scratch/drn2/software/stringtie-2.2.1.Linux_x86_64/stringtie
