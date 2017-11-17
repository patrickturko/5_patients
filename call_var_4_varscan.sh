#!/bin/bash

cd ../DNA/Exome/processed/6_bqsr_b37

foo9 () {
local tumor=$1
local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	echo ${NAME}
	mkdir ${NAME}
	mkdir ${NAME}/pileups
	samtools mpileup -f /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -l ../../intervals/S07604624_Covered.bed -q 1 -B --output ${NAME}.pileup ${tumor} ${normal};
	
	mv ${NAME}.pileup ${NAME}/pileups

	}

export -f foo9

for word in $(cat patient_names.txt)
do
sem -j 16 --id pileup foo9 $word/*$word*tumor*BQSR.bam $word/*$word*blood*BQSR.bam
done
sem --wait --id pileup



foo10() {
local i=$1
	NAME=`echo ${i} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	mkdir ${NAME}/varscan
	java -Xmx16G -jar /data/Phil/software/VarScan.v2.4.2.jar somatic ${i} --output-snp ${NAME}_snp_varscan.vcf --output-indel ${NAME}_indel_varscan.vcf --output-vcf 1 --mpileup 1
	mv ${NAME}*varscan.vcf ${NAME}/varscan
	
}
	
export -f foo10

for word in $(cat patient_names.txt)
do
sem -j 16 --id varscan foo10 $word/pileups/${word}.pileup 
done
sem --wait --id varscan

