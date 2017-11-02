#!/bin/bash

cd ../DNA/Exome/processed/2_skewer/test/6
ls *blood*BQSR.bam | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/' > patient_names.txt


foo10() {
local tumor=$1
local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`;
	java -Xmx16G -jar /data/Phil/software/VarScan.v2.4.2.jar somatic ${normal} ${tumor} ${NAME} --output-vcf 1
}
	
export -f foo10

for word in $(cat patient_names.txt)
do
sem -j 16 --id varscan foo10 $word/pileups/*$word*tumor*pileup.vcf $word/pileups/*$word*blood*pileup.vcf 
done
sem --wait --id varscan
