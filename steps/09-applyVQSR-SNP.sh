#!/bin/bash

set -o xtrace

source `pwd`/configuration.sh
OUTPUTDIR=`pwd`/09-ApplyVQSR
mkdir -p $OUTPUTDIR

INPUTSVCF=(07-GenotypeGVCFs/Genotypes.g.vcf.gz)
INPUTSTRANCHES=(08-VQSR/SNP.tranches)
INPUTSRECAL=(08-VQSR/SNP.recal)
echo "${INPUTS[@]}"

gatk --java-options -Djava.io.tempdir=`pwd`/tmp \
ApplyVQSR \
-V "${INPUTSVCF}"\
-R "${FASTA}" \
--mode SNP \
-ts-filter-level 99.6 \
-tranches-file "${INPUTSTRANCHES}" \
-recal-file "${INPUTSRECAL}" \
-O "${OUTPUTDIR}"/AppliedVQSR-SNP.g.vcf.gz \
--TMP_DIR "${OUTPUTDIR}"/TMP
