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
--mode SNP \
--resource v1000G,known=false,training=true,truth=false,prior=10.0:"${V1000G}" \
--resource omni,known=false,training=true,truth=true,prior=12.0:"${OMNI}" \
--resource dbsnp,known=true,training=false,truth=false,prior=2.0:"${DBSNP}" \
--resource hapmap,known=false,training=true,truth=true,prior=15.0:"${HAPMAP}" \
-an QD -an MQ -an DP -an MQRankSum -an ReadPosRankSum -an FS -an SOR \
-tranche 100.0 -tranche 99.95 -tranche 99.9 -tranche 99.8 -tranche 99.6 \
-tranche 99.5 -tranche 99.4 -tranche 99.3 -tranche 99.0 -tranche 98.0 \
-tranche 97.0 -tranche 90.0 \
--tranches-file "${OUTPUTDIR}"/SNP.tranches \
--output "${OUTPUTDIR}"/SNP.recal \
--max-gaussians 4 \
--TMP_DIR "${OUTPUTDIR}"/TMP_SNP
