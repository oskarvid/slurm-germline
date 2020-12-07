#!/bin/bash

set -o xtrace

source `pwd`/configuration.sh
OUTPUTDIR=`pwd`/08-VQSR
mkdir -p $OUTPUTDIR

INPUTS=(07-GenotypeGVCFs/Genotypes.g.vcf.gz)
echo "${INPUTS[@]}"

gatk --java-options -Djava.io.tempdir=`pwd`/tmp \
VariantRecalibrator \
-R "${FASTA}" \
-V "${INPUTS}" \
--mode INDEL \
--resource mills,known=false,training=true,truth=true,prior=12.0:"${MILLS}" \
--resource dbsnp,known=true,training=false,truth=false,prior=2.0:"${DBSNP}" \
-an QD -an DP -an FS -an SOR -an ReadPosRankSum -an MQRankSum -tranche 100.0 \
-tranche 99.95 -tranche 99.9 -tranche 99.5 -tranche 99.0 -tranche 97.0 -tranche 96.0 \
-tranche 95.0 -tranche 94.0 -tranche 93.5 -tranche 93.0 -tranche 92.0 -tranche 91.0 \
-tranche 90.0 \
--tranches-file "${OUTPUTDIR}"/INDEL.tranches \
--output "${OUTPUTDIR}"/INDEL.recal \
--max-gaussians 4 \
--TMP_DIR "${OUTPUTDIR}"/TMP_INDEL
