#!/bin/bash

cd ../../../DNA/Exome/processed/2_skewer/test/4/

rg_dir=`echo coverage`
mkdir -p "$rg_dir"

foo6 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	echo ${NAME}
	#samtools depth -b ../../../../intervals/S07604624_Regions.bed ${i} > ${i}.coverage
	java -Xmx16G -jar /data/Phil/software/GATK_3.7/GenomeAnalysisTK.jar -T DepthOfCoverage -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -L ../../../../intervals/targets.interval_list -o _coverage_stats

}
export -f foo6

for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id coverage foo6 "$i"
done
sem --wait --id coverage


