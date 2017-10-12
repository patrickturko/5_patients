#!/bin/bash

cd ../../../DNA/Exome/processed/2_skewer/

foo () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar ValidateSamFile I=${i} MODE=SUMMARY OUTPUT=${NAME}_validate_01_.txt
}

export -f foo

for i in *sorted_dedup_fixmate.bam
do 
sem -j 16 --id validate foo "$i"
done
sem --wait --id validate

mv *validate_01.txt test/3/


