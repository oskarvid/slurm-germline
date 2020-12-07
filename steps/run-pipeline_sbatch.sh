#!/bin/bash

# set -e will stop the execution if something fails
set -e

# This will print every command to the terminal to ease troubleshooting
set -o xtrace

# Read the config file to load file paths
source `pwd`/configuration.sh

# Read the input.tsv file into an array variable
readarray INPUT < <(cat `pwd`/input.tsv)

# Declare the following variables as arrays
declare -a BWA
declare -a FQTS
declare -a MBA
declare -a MD
declare -a BQSR
declare -a GBQSR
declare -a ABQSR
declare -a GABQSR
declare -a HTC
declare -a GHTC
declare -a GVCF
declare -a GGVCF
declare -a SVQSR
declare -a IVQSR
declare -a ASVQSR
declare -a AIVQSR

declare -a BWADEPS

# Account name variable 
ACCOUNTNAME="p172"

# Variables for BWA mem
BWATIME="00-01:00:00"
BWAMEM="8192"
BWANTASKS="${#INPUT[@]}"
BWANTASKSPERNODE="1"
BWATHREADS="16"

# Start one bwa process per input file
if [[ ! -d `pwd`/01-Bwa ]]; then
	for i in $(seq 1 ${#INPUT[@]}); do
		BWAJOBNAME="BWA_$i"
		BWA[$i]+="$(sbatch \
		--account=${ACCOUNTNAME} \
		--job-name=${BWAJOBNAME} \
		--time=${BWATIME} \
		--mem-per-cpu=${BWAMEM} \
		--ntasks=${BWANTASKS} \
		--ntasks-per-node=${BWANTASKSPERNODE} \
		--cpus-per-task=${BWATHREADS} \
		./01-bwa.sh $i | awk {'print $4'})"
	done
fi

# Variables for FastqToSam
FQTSTIME="00-01:00:00"
FQTSMEM="8192"
FQTSNTASKS="1"
FQTSNTASKSPERNODE="1"

# Start one FastqToSam process per input file
if [[ ! -d `pwd`/01-FastqToSam ]]; then
	for i in $(seq 1 ${#INPUT[@]}); do
		FQTSJOBNAME="FQTS_$i"
		FQTS[$i]+="$(sbatch \
		--account=${ACCOUNTNAME} \
		--job-name=${FQTSJOBNAME} \
		--time=${FQTSTIME} \
		--mem-per-cpu=${FQTSMEM} \
		--ntasks=${FQTSNTASKS} \
		--ntasks-per-node=${FQTSNTASKSPERNODE} \
	 	./01-fastqtosam.sh $i | awk {'print $4'})"
	done
fi

# Format bwa dependency list
for i in $(seq 1 "${#BWA[@]}"); do 
	let i=i-1
	BWADEPS[$i]+=$(echo ":${BWA[$i]}")
done
BWADEPS=$(echo "${BWADEPS[@]}" | sed 's/ //')

# Format FastqToSam dependency list
for i in $(seq 1 "${#FQTS[@]}"); do 
	let i=i-1
	FQTSDEPS[$i]+=$(echo ":${FQTS[$i]}")
done
FQTSDEPS=$(echo "${FQTSDEPS[@]}" | sed 's/ //')

# Variables for MergeBamAlignments
MBATIME="00-06:00:00"
MBAMEM="8192"
MBANTASKS="1"
MBANTASKSPERNODE="1"

# Merge the unmapped bam file from FastqToSam with the corresponding mapped bam file from bwa
if [[ ! -d `pwd`/02-MergeBamAlignment ]]; then
	for i in $(seq 1 ${#INPUT[@]}); do
		MBAJOBNAME="MergeBamAlignments_$i"
		MBA[$i]+="$(sbatch \
		--account=${ACCOUNTNAME} \
		--job-name=${MBAJOBNAME} \
		--time=${MBATIME} \
		--mem-per-cpu=${MBAMEM} \
		--ntasks=${MBANTASKS} \
		--ntasks-per-node=${MBANTASKSPERNODE} \
		--dependency=afterok"${BWADEPS}""${FQTSDEPS[@]}" \
		./02-mergebamalignment.sh $i | awk {'print $4'})"
	done
fi

# Format MergeBamAlignments dependency list
for i in $(seq 1 "${#MBA[@]}"); do 
	let i=i-1
	MBADEPS[$i]+=$(echo ":${MBA[$i]}")
done
MBADEPS=$(echo "${MBADEPS[@]}" | sed 's/ //')

# Variables for MarkDuplicates
MDJOBNAME="MarkDuplicates"
MDTIME="00-04:00:00"
MDMEM="8192"
MDNTASKS="1"
MDNTASKSPERNODE="1"

# Merge and mark duplicates in the output file from MergeBamAlignments
if [[ ! -d `pwd`/03-MarkDuplicates ]]; then
	MD="$(sbatch \
	--account=${ACCOUNTNAME} \
	--job-name=${MDJOBNAME} \
	--time=${MDTIME} \
	--mem-per-cpu=${MDMEM} \
	--ntasks=${MDNTASKS} \
	--ntasks-per-node=${MDNTASKSPERNODE} \
	--dependency=afterok"${MBADEPS}" \
	./03-markduplicates.sh | awk {'print $4'})"
fi

# Variables for BaseRecalibrator
BQSRTIME="00-01:00:00"
BQSRMEM="8192"
BQSRNTASKS="1"
BQSRNTASKSPERNODE="1"

# Start one BaseRecalibrator instance per contig file
if [[ ! -d `pwd`/04-BaseRecalibrator ]]; then
	for i in $(seq 1 "${#CONTIGS[@]}"); do
		BQSRJOBNAME="BaseRecalibrator_$i"
		BQSR[$i]+="$(sbatch \
		--account=${ACCOUNTNAME} \
		--job-name=${BQSRJOBNAME} \
		--time=${BQSRTIME} \
		--mem-per-cpu=${BQSRMEM} \
		--ntasks=${BQSRNTASKS} \
		--ntasks-per-node=${BQSRNTASKSPERNODE} \
		--dependency=afterok:${MD} \
		./04-baserecalibrator.sh $i | awk {'print $4'})"
	done
fi

# Format BaseRecalibrator dependency list
for i in $(seq 1 "${#BQSR[@]}"); do 
	let i=i-1
	BQSRDEPS[$i]+=$(echo ":${BQSR[$i]}")
done
BQSRDEPS=$(echo "${BQSRDEPS[@]}" | sed 's/ //')

# Variables for gathering of output from BaseRecalibrator
GBQSRJOBNAME="GatherBQSR"
GBQSRTIME="00-06:00:00"
GBQSRMEM="8192"
GBQSRNTASKS="1"
GBQSRNTASKSPERNODE="1"

# Gather the .grp files from the BaseRecalibrator step
if [[ ! -f `pwd`/04-BaseRecalibrator/BQSR.grp ]]; then
	GBQSR="$(sbatch \
	--account=${ACCOUNTNAME} \
	--job-name=${GBQSRJOBNAME} \
	--time=${GBQSRTIME} \
	--mem-per-cpu=${GBQSRMEM} \
	--ntasks=${GBQSRNTASKS} \
	--ntasks-per-node=${GBQSRNTASKSPERNODE} \
	--dependency=afterok${BQSRDEPS} \
	./04.1-gatherbqsr.sh | awk {'print $4'})"
fi

# Variables for ApplyBQSR
ABQSRTIME="00-01:00:00"
ABQSRMEM="8192"
ABQSRNTASKS="1"
ABQSRNTASKSPERNODE="1"

# Start one ApplyBQSR process per contig file
if [[ ! -d `pwd`/05-ApplyBQSR ]]; then
	for i in $(seq 1 "${#CONTIGS[@]}"); do
		ABQSRJOBNAME="ApplyBQSR_$i"
		ABQSR[$i]+="$(sbatch \
		--account=${ACCOUNTNAME} \
		--job-name=${ABQSRJOBNAME} \
		--time=${ABQSRTIME} \
		--mem-per-cpu=${ABQSRMEM} \
		--ntasks=${ABQSRNTASKS} \
		--ntasks-per-node=${ABQSRNTASKSPERNODE} \
		--dependency=afterok:${GBQSR} \
		./05-applyBQSR.sh $i | awk {'print $4'})"
	done
fi

# Format BaseRecalibrator dependency list
for i in $(seq 1 "${#ABQSR[@]}"); do 
	let i=i-1
	ABQSRDEPS[$i]+=$(echo ":${ABQSR[$i]}")
done
ABQSRDEPS=$(echo "${ABQSRDEPS[@]}" | sed 's/ //')

# Variables for gathering of ApplyBQSR
GABQSRJOBNAME="GatherApplyBQSR"
GABQSRTIME="00-06:00:00"
GABQSRMEM="8192"
GABQSRNTASKS="1"
GABQSRNTASKSPERNODE="1"

# Gather the bam files from ApplyBQSR
if [[ ! -f `pwd`/05-ApplyBQSR/AppliedBQSR.bam ]]; then
	GABQSR="$(sbatch \
	--account=${ACCOUNTNAME} \
	--job-name=${GABQSRJOBNAME} \
	--time=${GABQSRTIME} \
	--mem-per-cpu=${GABQSRMEM} \
	--ntasks=${GABQSRNTASKS} \
	--ntasks-per-node=${GABQSRNTASKSPERNODE} \
	--dependency=afterok${ABQSRDEPS} \
	./05.1-gatherapplybqsr.sh | awk {'print $4'})"
fi

# Variables for HaplotypeCaller
HTCTIME="00-01:00:00"
HTCMEM="8192"
HTCNTASKS="1"
HTCNTASKSPERNODE="1"

# Start one HaplotypeCaller process per interval list
if [[ ! -d `pwd`/06-HaplotypeCaller ]]; then
	for i in $(seq 1 "${#INTERVALS[@]}"); do
		HTCJOBNAME="HaplotypeCaller_$i"
		HTC[$i]+="$(sbatch \
		--account=${ACCOUNTNAME} \
		--job-name=${HTCJOBNAME} \
		--time=${HTCTIME} \
		--mem-per-cpu=${HTCMEM} \
		--ntasks=${HTCNTASKS} \
		--ntasks-per-node=${HTCNTASKSPERNODE} \
		--dependency=afterok:${GABQSR} \
		./06-haplotypecaller.sh $i | awk {'print $4'})"
	done
fi

# Format BaseRecalibrator dependency list
for i in $(seq 1 "${#HTC[@]}"); do 
	let i=i-1
	HTCDEPS[$i]+=$(echo ":${HTC[$i]}")
done
HTCDEPS=$(echo "${HTCDEPS[@]}" | sed 's/ //')

# Variables for gathering output from HaplotypeCaller
GHTCJOBNAME="GatherHaplotypeCaller"
GHTCTIME="00-02:00:00"
GHTCMEM="8192"
GHTCNTASKS="1"
GHTCNTASKSPERNODE="1"

# Gather the vcf files from HaplotypeCaller
if [[ ! -f `pwd`/06-HaplotypeCaller/HaplotypeCaller.g.vcf.gz ]]; then
	GHTC="$(sbatch \
	--account=${ACCOUNTNAME} \
	--job-name=${GHTCJOBNAME} \
	--time=${GHTCTIME} \
	--mem-per-cpu=${GHTCMEM} \
	--ntasks=${GHTCNTASKS} \
	--ntasks-per-node=${GHTCNTASKSPERNODE} \
	--dependency=afterok${HTCDEPS} \
	./06.1-gathervcfs.sh | awk {'print $4'})"
fi

# Variables for GenotypeGVCFs
GVCFTIME="00-01:00:00"
GVCFMEM="8192"
GVCFNTASKS="1"
GVCFNTASKSPERNODE="1"

# Start one GenotypeGVCFs process per contig file
if [[ ! -d `pwd`/07-GenotypeGVCFs ]]; then
	for i in $(seq 1 "${#CONTIGS[@]}"); do
		GVCFJOBNAME="GVCF_$i"
		GVCF[$i]+="$(sbatch \
		--account=${ACCOUNTNAME} \
		--job-name=${GVCFJOBNAME} \
		--time=${GVCFTIME} \
		--mem-per-cpu=${GVCFMEM} \
		--ntasks=${GVCFNTASKS} \
		--ntasks-per-node=${GVCFNTASKSPERNODE} \
		--dependency=afterok:${GHTC} \
		./07-genotypegvcfs.sh $i | awk {'print $4'})"
	done
fi

# Format BaseRecalibrator dependency list
for i in $(seq 1 "${#GVCF[@]}"); do 
	let i=i-1
	GVCFDEPS[$i]+=$(echo ":${GVCF[$i]}")
done
GVCFDEPS=$(echo "${GVCFDEPS[@]}" | sed 's/ //')

# Variables for gathering of output from GenotypGVCFs
GGVCFJOBNAME="GatherGVCF"
GGVCFTIME="00-01:00:00"
GGVCFMEM="8192"
GGVCFNTASKS="1"
GGVCFNTASKSPERNODE="1"

# Gather the vcf files from GenotypeGVCFs
if [[ ! -f `pwd`/07-GenotypeGVCFs/Genotypes.g.vcf.gz ]]; then
	GGVCF="$(sbatch \
	--account=${ACCOUNTNAME} \
	--job-name=${GGVCFJOBNAME} \
	--time=${GGVCFTIME} \
	--mem-per-cpu=${GGVCFMEM} \
	--ntasks=${GGVCFNTASKS} \
	--ntasks-per-node=${GGVCFNTASKSPERNODE} \
	--dependency=afterok${GVCFDEPS} \
	./07.1-gathervcfs.sh | awk {'print $4'})"
fi

# Variables for VariantRecalibrator for SNPs
SVQSRJOBNAME="VariantRecalibration"
SVQSRTIME="00-01:00:00"
SVQSRMEM="8192"
SVQSRNTASKS="1"
SVQSRNTASKSPERNODE="1"

# Run variant recalibration for SNPs
if [[ ! -d `pwd`/08-VQSR ]]; then
	SVQSR="$(sbatch \
	--account=${ACCOUNTNAME} \
	--job-name=${SVQSRJOBNAME} \
	--time=${SVQSRTIME} \
	--mem-per-cpu=${SVQSRMEM} \
	--ntasks=${SVQSRNTASKS} \
	--ntasks-per-node=${SVQSRNTASKSPERNODE} \
	--dependency=afterok:${GGVCF} \
	./08-VQSR-SNP.sh | awk {'print $4'})"
fi

# Variables for VariantRecalibrator for Indels
IVQSRJOBNAME="GRS_IVQSR"
IVQSRTIME="00-01:00:00"
IVQSRMEM="8192"
IVQSRNTASKS="1"
IVQSRNTASKSPERNODE="1"

# Run variant recalibration for Indels
if [[ ! -d `pwd`/08-VQSR ]]; then
	IVQSR="$(sbatch \
	--account=${ACCOUNTNAME} \
	--job-name=${IVQSRJOBNAME} \
	--time=${IVQSRTIME} \
	--mem-per-cpu=${IVQSRMEM} \
	--ntasks=${IVQSRNTASKS} \
	--ntasks-per-node=${IVQSRNTASKSPERNODE} \
	--dependency=afterok:${GGVCF} \
	./08-VQSR-INDEL.sh | awk {'print $4'})"
fi

# Variables for Apply VQSR for SNPs
ASVQSRJOBNAME="ApplySnpVQSR"
ASVQSRTIME="00-01:00:00"
ASVQSRMEM="8192"
ASVQSRNTASKS="1"
ASVQSRNTASKSPERNODE="1"

# Apply variant recalibration for SNPs
if [[ ! -d `pwd`/09-ApplyVQSR ]]; then
	ASVQSR="$(sbatch \
	--account=${ACCOUNTNAME} \
	--job-name=${ASVQSRJOBNAME} \
	--time=${ASVQSRTIME} \
	--mem-per-cpu=${ASVQSRMEM} \
	--ntasks=${ASVQSRNTASKS} \
	--ntasks-per-node=${ASVQSRNTASKSPERNODE} \
	--dependency=afterok:${SVQSR} \
	./09-applyVQSR-SNP.sh | awk {'print $4'})"
fi

# Variables for Apply VQSR for Indels
AIVQSRJOBNAME="ApplyIndelVQSR"
AIVQSRTIME="00-01:00:00"
AIVQSRMEM="8192"
AIVQSRNTASKS="1"
AIVQSRNTASKSPERNODE="1"

# Apply variant recalibration for Indels
if [[ ! -d `pwd`/09-ApplyVQSR ]]; then
	AIVQSR="$(sbatch \
	--account=${ACCOUNTNAME} \
	--job-name=${AIVQSRJOBNAME} \
	--time=${AIVQSRTIME} \
	--mem-per-cpu=${AIVQSRMEM} \
	--ntasks=${AIVQSRNTASKS} \
	--ntasks-per-node=${AIVQSRNTASKSPERNODE} \
	--dependency=afterok:${IVQSR} \
	./09-applyVQSR-INDEL.sh | awk {'print $4'})"
fi
