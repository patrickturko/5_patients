#!/bin/bash

cd ../../../DNA/Exome/processed/2_skewer/test/4/

rg_dir=`echo coverage`
mkdir -p "$rg_dir"

foo6 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	echo ${NAME}
	samtools depth -b ../../../../intervals/S07604624_Regions.bed ${i} > ${i}.coverage
	#awk '$1 == 1 {print $0}' deduped_MA605.coverage > chr1_MA605.coverage

}
export -f foo6

for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id coverage foo6 "$i"
done
sem --wait --id coverage

