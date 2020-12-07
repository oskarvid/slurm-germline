#!/bin/bash

set -o xtrace

source `pwd`/configuration.sh
OUTPUTDIR=`pwd`/07-GenotypeGVCFs
mkdir -p $OUTPUTDIR

INPUTS=(06-HaplotypeCaller/HaplotypeCaller.g.vcf.gz)
echo "${INPUTS[@]}"

CONTIGS=$(ls `pwd`/intervals/contigs/$1.bed)
echo "${CONTIGS}"

gatk --java-options '-Xmx3500M -Djava.io.tempdir=`pwd`/tmp' \
GenotypeGVCFs \
-R "${FASTA}" \
-O "${OUTPUTDIR}"/Genotypes_$1.g.vcf.gz \
-V "${INPUTS}" \
-L "${CONTIGS}" \
--TMP_DIR $OUTPUTDIR/TMP_$1
