#!/bin/bash

set -o xtrace

source `pwd`/configuration.sh
OUTPUTDIR=`pwd`/09-ApplyVQSR
mkdir -p $OUTPUTDIR

INPUTSVCF=(07-GenotypeGVCFs/Genotypes.g.vcf.gz)
INPUTSTRANCHES=(08-VQSR/INDEL.tranches)
INPUTSRECAL=(08-VQSR/INDEL.recal)

gatk --java-options -Djava.io.tempdir=`pwd`/tmp \
ApplyVQSR \
-V "${INPUTSVCF}" \
-R "${FASTA}" \
--mode INDEL \
-ts-filter-level 95.0 \
-tranches-file "${INPUTSTRANCHES}" \
-recal-file "${INPUTSRECAL}" \
-O "${OUTPUTDIR}"/AppliedVQSR-INDEL.g.vcf.gz \
--TMP_DIR "${OUTPUTDIR}"/TMP
