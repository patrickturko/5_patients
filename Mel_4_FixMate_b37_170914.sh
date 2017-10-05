#!/bin/bash


rg_dir3=`echo 5_fixmate_b37`
mkdir -p "$rg_dir3"

foo3 () {
local i=$1
	OUTPUT_DIR=`echo ./5_fixmate/`
	#OUTPUT_DIR2=`echo ./GATK_RNA_dedup/`
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup.bam/\1/'`;
	echo ${NAME}
	java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar FixMateInformation VALIDATION_STRINGENCY=SILENT CREATE_INDEX=true SORT_ORDER=coordinate I=${i} O=${NAME}_sorted_dedup_fixmate.bam 
}
export -f foo3
for i in *sorted_dedup.bam
do
sem -j 16 --id fixmate foo3 "$i"
done
sem --wait --id fixmate

