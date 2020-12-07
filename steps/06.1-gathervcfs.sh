#!/bin/bash

set -o xtrace
set -a FIXEDINPUTS

source `pwd`/configuration.sh
OUTPUTDIR=`pwd`/06-HaplotypeCaller

INPUTS=($OUTPUTDIR/*_[0-9]*.g.vcf.gz)
#echo "${INPUTS[@]}"

for i in $(seq 1 "${#INPUTS[@]}"); do
	let j=i
	let i=i-1
	FIXEDINPUTS[$i]+=$(echo "-I $(ls $OUTPUTDIR/*_$j.g.vcf.gz)")
done

echo "${FIXEDINPUTS[@]}"

gatk --java-options -Djava.io.tempdir=`pwd`/tmp \
MergeVcfs \
$(echo "${FIXEDINPUTS[@]}") \
-O "${OUTPUTDIR}"/HaplotypeCaller.g.vcf.gz \
--CREATE_INDEX true
