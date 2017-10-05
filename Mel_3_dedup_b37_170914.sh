#!/bin/bash

rg_dir2=`echo 4_dedup_b37`
mkdir -p "$rg_dir2"

foo2 () {
local i=$1
	#OUTPUT_DIR=`echo 4_dedup/`
	#OUTPUT_DIR2=`echo ./GATK_RNA_dedup/`
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted.bam/\1/'`;
	echo ${NAME}
	java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar MarkDuplicates I=${i} O=${NAME}_sorted_dedup.bam  M=${NAME}_metrics.txt
}
export -f foo2

for i in *sorted.bam
do
sem -j 16 --id dedup foo2 "$i"
done
sem --wait --id dedup

