#!/bin/bash

source `pwd`/configuration.sh

OUTPUTDIR=`pwd`/01-FastqToSam/
mkdir -p $OUTPUTDIR

readarray INPUT < <(cat `pwd`/input.tsv)

let i=$1-1
FC[$i]+=$(echo "${INPUT[$i]}" | awk '{ print $1 }')
SM[$i]+=$(echo "${INPUT[$i]}" | awk '{ print $2 }')
LB[$i]+=$(echo "${INPUT[$i]}" | awk '{ print $3 }')
LN[$i]+=$(echo "${INPUT[$i]}" | awk '{ print $4 }')
SAMPLES1[$i]+=$(echo "${INPUT[$i]}" | awk '{ print $5 }')
SAMPLES2[$i]+=$(echo "${INPUT[$i]}" | awk '{ print $6 }')
ID[$i]+=$(echo "${FC[$i]}"."${SM[$i]}"."${LN[$i]}")
READGROUP[$i]+="@RG\tID:"${ID[$i]}"\tSM:"${SM[$i]}"\tLB:"${LB[$i]}"\tPL:ILLUMINA\tPU:NotDefined"

echo "Starting FastqToSam with input files "${SAMPLES1[$i]}" and "${SAMPLES2[$i]}""
gatk --java-options -Djava.io.tempdir=`pwd`/tmp \
  FastqToSam \
  --FASTQ "${SAMPLES1[$i]}" \
  --FASTQ2 "${SAMPLES2[$i]}" \
  -O $OUTPUTDIR/FastqToSam_"${ID[$i]}".bam \
  --SAMPLE_NAME "${SM[$i]}" \
  --READ_GROUP_NAME "${ID[$i]}" \
  --LIBRARY_NAME "${LB[$i]}" \
  --PLATFORM ILLUMINA \
  --TMP_DIR "${OUTPUTDIR}"/FastqToSam-"$i"_TMP
rm -r "${OUTPUTDIR}"/FastqToSam-"$i"_TMP
