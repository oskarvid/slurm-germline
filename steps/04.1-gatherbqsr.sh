#!/bin/bash

set -o xtrace
set -a FIXEDINPUTS

source `pwd`/configuration.sh
OUTPUTDIR=`pwd`/04-BaseRecalibrator
mkdir -p $OUTPUTDIR

INPUTS=(`pwd`/04-BaseRecalibrator/*_[0-9]*.grp)
#echo "${INPUTS[@]}"

for i in $(seq 1 "${#INPUTS[@]}"); do
	let j=i
	let i=i-1
	FIXEDINPUTS[$i]+=$(echo "-I $(ls `pwd`/04-BaseRecalibrator/*_$j.grp)")
done

echo "${FIXEDINPUTS[@]}"

gatk --java-options -Djava.io.tempdir=`pwd`/tmp \
GatherBQSRReports \
$(echo "${FIXEDINPUTS[@]}") \
-O "${OUTPUTDIR}"/BQSR.grp
