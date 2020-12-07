#!/bin/bash

set -o xtrace

source `pwd`/configuration.sh
OUTPUTDIR=`pwd`/07-GenotypeGVCFs
mkdir -p $OUTPUTDIR

INPUTS=(06-HaplotypeCaller/*.vcf.gz)
echo "${INPUTS[@]}"

gatk --java-options '-Xmx3500M -Djava.io.tempdir=`pwd`/tmp' \
GenotypeGVCFs \
-R "${FASTA}" \
-O "${OUTPUTDIR}"/Genotypes.vcf.gz \
-V "${INPUTS[@]}" \
-L "${INTERVALS}" \
--TMP_DIR $OUTPUTDIR/TMP
