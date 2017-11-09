#!/bin/bash

cd ../DNA/Exome/processed/test/6
ls *blood*BQSR.bam | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/' > patient_names.txt

foo9 () {
local tumor=$1
local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	echo ${NAME}
	mkdir ${NAME}
	mkdir ${NAME}/pileups
	samtools mpileup -f /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -l ../../../intervals/S07604624_Covered.bed -v --output ${NAME}_pileup.vcf ${tumor} ${normal};
	mv *pileup.vcf ${NAME}/pileups

	}

export -f foo9

for word in $(cat patient_names.txt)
do
sem -j 16 --id pileup foo9 *$word*tumor*BQSR.bam *$word*blood*BQSR.bam
done
sem --wait --id pileup

