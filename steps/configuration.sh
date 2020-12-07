#!/bin/bash

declare -a CONTIGS
declare -a INTERVALS

REFERENCES="/home/oskar/01-workspace/01-data/refdata/hg38"
#REFERENCES="/references"

DBSNP=$REFERENCES/dbsnp_146.hg38.vcf.gz
HAPMAP=$REFERENCES/hapmap_3.3.hg38.vcf.gz
OMNI=$REFERENCES/1000G_omni2.5.hg38.vcf.gz
FASTA=$REFERENCES/Homo_sapiens_assembly38.fasta
V1000G=$REFERENCES/1000G_phase1.snps.high_confidence.hg38.vcf.gz
MILLS=$REFERENCES/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz

#INTERVALS=$REFERENCES/HG001_GRCh38_GIAB_highconf_CG-IllFB-IllGATKHC-Ion-10X-SOLID_CHROM1-X_v.3.3.2_highconf_nosomaticdel_noCENorHET7.bed
INTERVALS=`pwd`/intervals
CONTIGS=($INTERVALS/contigs/*)
INTERVALS=($INTERVALS/16-lists/*/*)
