#!/bin/bash

declare -a FC
declare -a SM
declare -a LB
declare -a LN
declare -a SAMPLES
declare -a ID
declare -a READGROUP

source `pwd`/configuration.sh
OUTPUTDIR=`pwd`/02-MergeBamAlignment/
mkdir -p $OUTPUTDIR

BWA=(01-Bwa/*.bam)
FQTS=(01-FastqToSam/*.bam)

let i=$1-1
	gatk --java-options -Djava.io.tempdir=`pwd`/tmp \
	MergeBamAlignment \
	--VALIDATION_STRINGENCY SILENT \
	--EXPECTED_ORIENTATIONS FR \
	--ATTRIBUTES_TO_RETAIN X0 \
	--ALIGNED_BAM "${BWA[$i]}" \
	--UNMAPPED_BAM "${FQTS[$i]}" \
	-O "${OUTPUTDIR}"/FastqToSam_"$i".bam \
	--REFERENCE_SEQUENCE "${FASTA}" \
	--SORT_ORDER coordinate \
	--IS_BISULFITE_SEQUENCE false \
	--ALIGNED_READS_ONLY false \
	--CLIP_ADAPTERS false \
	--MAX_RECORDS_IN_RAM 200000 \
	--ADD_MATE_CIGAR true \
	--MAX_INSERTIONS_OR_DELETIONS -1 \
	--PRIMARY_ALIGNMENT_STRATEGY MostDistant \
	--PROGRAM_RECORD_ID 'bwamem' \
	--PROGRAM_GROUP_VERSION '0.7.12-r1039' \
	--PROGRAM_GROUP_COMMAND_LINE 'bwa mem -t 18 -R -M Input1 Input2 > output.sam' \
	--PROGRAM_GROUP_NAME 'bwamem' \
	--TMP_DIR "${OUTPUTDIR}"/"$i"_TMP
