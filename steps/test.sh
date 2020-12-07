#!/bin/bash

declare -a FC
declare -a SM
declare -a LB
declare -a LN
declare -a SAMPLES
declare -a ID
declare -a READGROUP

#while IFS='' read -r line || [[ -n "$line" ]]; do
#readarray INPUT < <(echo "$line")
#done < `pwd`/input.tsv

source `pwd`/configuration.sh

readarray INPUT < <(cat `pwd`/input.tsv)

for i in $(seq 1 ${#INPUT[@]}); do
	let i=i-1
	FC[$i]+=$(echo "${INPUT[$i]}" | awk '{ print $1 }')
	SM[$i]+=$(echo "${INPUT[$i]}" | awk '{ print $2 }')
	LB[$i]+=$(echo "${INPUT[$i]}" | awk '{ print $3 }')
	LN[$i]+=$(echo "${INPUT[$i]}" | awk '{ print $4 }')
	SAMPLES1[$i]+=$(echo "${INPUT[$i]}" | awk '{ print $5 }')
	SAMPLES2[$i]+=$(echo "${INPUT[$i]}" | awk '{ print $6 }')
	ID[$i]+=$(echo "${FC[$i]}"."${SM[$i]}"."${LN[$i]}")
	READGROUP[$i]+="@RG\tID:"${ID[$i]}"\tSM:"${SM[$i]}"\tLB:"${LB[$i]}"\tPL:ILLUMINA\tPU:NotDefined"
done

echo "${LN[@]}"
echo "${LB[@]}"
echo "${FC[@]}"
echo "${ID[@]}"

echo "This is SAMPLES1 "${SAMPLES1[0]}""
echo "This is SAMPLES2 "${SAMPLES2[1]}""

echo "${READGROUP[@]}"

#for i in $(seq 1 ${#INPUT[@]}); do
#	let i=i-1
#	echo "Starting bwa mem with input files "${SAMPLES[$i]}""
#	bwa mem -t 2 \
#	  -R "${READGROUP[$i]}" \
#	  -M ${FASTA} ${SAMPLES[$i]} \
#	  | samtools view -bS - \
#	  > ${FC[$i]}-${SM[$i]}-${LN[$i]}.bam
#done
