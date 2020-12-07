#!/bin/bash

set -o xtrace

source `pwd`/configuration.sh
#source `pwd`/run-pipeline.sh

OUTPUTDIR=`pwd`/01-Bwa/
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

echo "Starting bwa mem with input files "${SAMPLES1[$i]}" and "${SAMPLES2[$i]}""
bwa mem -t 2 \
  -R "${READGROUP[$i]}" \
  -M "${FASTA}" "${SAMPLES1[$i]}" "${SAMPLES2[$i]}" \
  | samtools view -bS - \
  > $OUTPUTDIR/Bwa_"${FC[$i]}"-"${SM[$i]}"-"${LN[$i]}".bam


