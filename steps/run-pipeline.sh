#!/bin/bash

set -e

set -o xtrace

declare -a BWA
declare -a FQTS

source `pwd`/configuration.sh
readarray INPUT < <(cat `pwd`/input.tsv)

# Start one bwa process per input file
if [[ ! -d `pwd`/01-Bwa ]]; then
	for i in $(seq 1 ${#INPUT[@]}); do
	#	BWA[$i]+="$(sbatch 01-bwa.sh $i | awk {'print $4'})"
	#	BWA[$i]+="$(./01-bwa.sh $i | awk {'print $4'})"
		./01-bwa.sh $i
	done
fi

# Start one FastqToSam process per input file
if [[ ! -d `pwd`/01-FastqToSam ]]; then
	for i in $(seq 1 ${#INPUT[@]}); do
	#	FQTS[$i]+="$(sbatch 01-fastqtosam.sh $i | awk {'print $4'})"
		./01-fastqtosam.sh $i
	done
fi

# Merge the unmapped bam file from FastqToSam with the corresponding mapped bam file from bwa
if [[ ! -d `pwd`/02-MergeBamAlignment ]]; then
	for i in $(seq 1 ${#INPUT[@]}); do
	#	FQTS[$i]+="$(sbatch 01-fastqtosam.sh $i | awk {'print $4'})"
		./02-mergebamalignment.sh $i
	done
fi

# Merge and mark duplicates in the output file from MergeBamAlignments
if [[ ! -d `pwd`/03-MarkDuplicates ]]; then
	./03-markduplicates.sh
fi

# Start one BaseRecalibrator instance per contig file
if [[ ! -d `pwd`/04-BaseRecalibrator ]]; then
	for i in $(seq 1 "${#CONTIGS[@]}"); do
		./04-baserecalibrator.sh $i
	done
fi

# Gather the .grp files from the BaseRecalibrator step
if [[ ! -f `pwd`/04-BaseRecalibrator/BQSR.grp ]]; then
	./04.1-gatherbqsr.sh
fi

# Start one ApplyBQSR process per contig file
if [[ ! -d `pwd`/05-ApplyBQSR ]]; then
	for i in $(seq 1 "${#CONTIGS[@]}"); do
		./05-applyBQSR.sh $i
	done
fi

# Gather the bam files from ApplyBQSR
if [[ ! -f `pwd`/05-ApplyBQSR/AppliedBQSR.bam ]]; then
	./05.1-gatherapplybqsr.sh
fi

# Start one HaplotypeCaller process per interval list
if [[ ! -d `pwd`/06-HaplotypeCaller ]]; then
	for i in $(seq 1 "${#INTERVALS[@]}"); do
		./06-haplotypecaller.sh $i
	done
fi

# Gather the vcf files from HaplotypeCaller
if [[ ! -f `pwd`/06-HaplotypeCaller/HaplotypeCaller.g.vcf.gz ]]; then
	./06.1-gathervcfs.sh
fi

# Start one GenotypeGVCFs process per contig file
if [[ ! -d `pwd`/07-GenotypeGVCFs ]]; then
	for i in $(seq 1 "${#CONTIGS[@]}"); do
		./07-genotypegvcfs.sh $i
	done
fi

# Gather the vcf files from GenotypeGVCFs
if [[ ! -f `pwd`/07-GenotypeGVCFs/Genotypes.g.vcf.gz ]]; then
	./07.1-gathervcfs.sh
fi

# Run variant recalibration for SNPs and INDELs
if [[ ! -d `pwd`/08-VQSR ]]; then
	./08-VQSR-INDEL.sh
	./08-VQSR-SNP.sh
fi

# Apply variant recalibration for SNPs and INDELs
if [[ ! -d `pwd`/09-ApplyVQSR ]]; then
	./09-applyVQSR-INDEL.sh
	./09-applyVQSR-SNP.sh
fi
