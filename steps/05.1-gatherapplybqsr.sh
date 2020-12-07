#!/bin/bash

set -o xtrace
set -a FIXEDINPUTS

source `pwd`/configuration.sh
OUTPUTDIR=`pwd`/05-ApplyBQSR

INPUTS=(`pwd`/05-ApplyBQSR/*_[0-9]*.bam)
#echo "${INPUTS[@]}"

for i in $(seq 1 "${#INPUTS[@]}"); do
	let j=i
	let i=i-1
	FIXEDINPUTS[$i]+=$(echo "-I $(ls `pwd`/05-ApplyBQSR/*_$j.bam)")
done

echo "${FIXEDINPUTS[@]}"

gatk --java-options -Djava.io.tempdir=`pwd`/tmp \
GatherBamFiles \
$(echo "${FIXEDINPUTS[@]}") \
-O "${OUTPUTDIR}"/AppliedBQSR.bam \
--CREATE_INDEX true
