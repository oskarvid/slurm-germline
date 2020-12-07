#!/bin/bash

set -o xtrace
set -a FIXEDINPUTS

source `pwd`/configuration.sh
OUTPUTDIR=`pwd`/03-MarkDuplicates
mkdir -p $OUTPUTDIR

INPUTS=(02-MergeBamAlignment/*.bam)
echo "${INPUTS[@]}"

for i in $(seq 1 "${#INPUTS[@]}"); do
	let i=i-1
	FIXEDINPUTS[$i]+=$(echo "-I ${INPUTS[$i]}")
done

echo "${FIXEDINPUTS[@]}"

gatk --java-options -Djava.io.tempdir=`pwd`/tmp \
MarkDuplicates \
$(echo "${FIXEDINPUTS[@]}") \
-O "${OUTPUTDIR}"/markedDuplicates.bam \
--VALIDATION_STRINGENCY LENIENT \
--METRICS_FILE "${OUTPUTDIR}"/markedDuplicates.metrics \
--MAX_FILE_HANDLES_FOR_READ_ENDS_MAP 200000 \
--CREATE_INDEX true \
--TMP_DIR "${OUTPUTDIR}"/TMP
