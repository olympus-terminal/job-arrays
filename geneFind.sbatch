#!/bin/bash
#SBATCH --job-name=gene_finding
#SBATCH --output=gene_finding_%j.out
#SBATCH --error=gene_finding_%j.err
#SBATCH --time=48:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH -p bigmem
#SBATCH --mem=1000G

#module load hisat2 stringtie samtools gffread bedtools braker
module load gencore
module load gencore_rnaseq

./gene_finding_pipeline.sh -g GORILLA-ONT_reads_2batch-all-HIFI_ONT.asm.bp.p_ctg.fa \
                           -1 IG1_NGS24-F857_AHHW2JDSXC_S1_L001_R1_001.fastq.gz \
                           -2 IG1_NGS24-F857_AHHW2JDSXC_S1_L001_R2_001.fastq.gz \
                           -i GORILLA-ONT_reads_2batch-all-HIFI_ONT.asm.bp.p_ctg.fa.tr.fa.transdecoder.gff3 \
                           -o geneFind.ou \
                           -t 32
