#!/bin/bash

set -o xtrace

source `pwd`/configuration.sh
OUTPUTDIR=`pwd`/05-ApplyBQSR
mkdir -p $OUTPUTDIR

BAMINPUTS=(03-MarkDuplicates/*.bam)
BQSRINPUTS=(04-BaseRecalibrator/BQSR.grp)
echo "${BAMINPUTS[@]}"
echo "${BQSRINPUTS[@]}"

CONTIGS=$(ls `pwd`/intervals/contigs/$1.bed)
echo "${CONTIGS}"

gatk --java-options -Djava.io.tempdir=`pwd`/tmp \
ApplyBQSR \
--reference "${FASTA}" \
--input "${BAMINPUTS}" \
-O $OUTPUTDIR/ApplyBQSR_$1.bam \
--create-output-bam-index true \
-bqsr "${BQSRINPUTS}" \
--intervals "${CONTIGS}" \
--TMP_DIR $OUTPUTDIR/TMP_$1
