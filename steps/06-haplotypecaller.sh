#!/bin/bash

set -o xtrace

source `pwd`/configuration.sh
OUTPUTDIR=`pwd`/06-HaplotypeCaller
mkdir -p $OUTPUTDIR

INPUTS=(05-ApplyBQSR/AppliedBQSR.bam)
echo "${INPUTS[@]}"

INTERVALS=$(ls `pwd`/intervals/16-lists/$1_of_16/scattered.bed)
echo "${INTERVALS}"

gatk --java-options '-Xmx3500M -Djava.io.tempdir=`pwd`/tmp' \
HaplotypeCaller \
-R "${FASTA}" \
-O "${OUTPUTDIR}"/HaplotypeCaller_$1.g.vcf.gz \
-I "${INPUTS}" \
-L "${INTERVALS[$i]}" \
-ERC GVCF \
--TMP_DIR $OUTPUTDIR/TMP_$1
