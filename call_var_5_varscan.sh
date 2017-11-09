#!/bin/bash

cd ../DNA/Exome/processed/6_bqsr_b37



foo10() {
local i=$1
	NAME=`echo ${i} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	java -Xmx16G -jar /data/Phil/software/VarScan.v2.4.2.jar somatic -mpileup ${i} --output-vcf 1 

	# What file does Varscan emit? Make a directory and move it there. 
	# This section hasn't been tested, do it individually with call_var_5_varscan.sh
}
	
export -f foo10

for word in $(cat patient_names.txt)
do
sem -j 16 --id varscan foo10 $word/pileups/*pileup_rearranged.vcf 
done
sem --wait --id varscan
