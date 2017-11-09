#!/bin/bash

cd ../DNA/Exome/processed/test/6
# ls *blood*BQSR.bam | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/' > patient_names.txt

foo9 () {
local tumor=$1
local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	echo ${NAME}
	mkdir ${NAME}
	mkdir ${NAME}/pileups
	samtools mpileup -f /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -l ../../../intervals/S07604624_Covered.bed -q 1 -B --output ${NAME}_pileup.vcf ${tumor} ${normal};
	
	mv *pileup.vcf ${NAME}/pileups

	}

export -f foo9

for word in $(cat patient_names.txt)
do
sem -j 16 --id pileup foo9 *$word*tumor*BQSR.bam *$word*blood*BQSR.bam
done
sem --wait --id pileup

foo10() {
local i=$1
	NAME=`echo ${i} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`

	java -Xmx16G -jar /data/Phil/software/VarScan.v2.4.2.jar somatic ${i} --output-vcf 1 --mpileup 1

	# What file does Varscan emit? Make a directory and move it there. 
	# This section hasn't been tested, do it individually with call_var_5_varscan.sh
}
	
export -f foo10

for word in $(cat patient_names.txt)
do
sem -j 16 --id varscan foo10 $word/pileups/*pileup_rearranged.vcf 
done
sem --wait --id varscan
