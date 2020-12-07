#!/bin/bash

set -o xtrace

source `pwd`/configuration.sh
OUTPUTDIR=`pwd`/04-BaseRecalibrator
mkdir -p $OUTPUTDIR

INPUTS=(03-MarkDuplicates/*.bam)
echo "${INPUTS[@]}"

echo $1

CONTIGS=$(ls `pwd`/intervals/contigs/$1.bed)
echo "${CONTIGS}"

gatk --java-options -Djava.io.tempdir=`pwd`/tmp \
BaseRecalibrator \
--reference "${FASTA}" \
--input "${INPUTS}" \
-O $OUTPUTDIR/BQSR_$1.grp \
--known-sites "${DBSNP}" \
--known-sites "${V1000G}" \
--known-sites "${MILLS}" \
--intervals "${CONTIGS}" \
--TMP_DIR $OUTPUTDIR/TMP

