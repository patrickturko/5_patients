#!/bin/bash

cd /data2/patrick/Patients/DNA/Exome/processed/2_skewer/6_bqsr_b37/

foo8 () {
local i=$1
NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_BQSR.bam/\1/'`;
	java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar CollectHsMetrics I=${i} O=${NAME}_hs_metrics.txt  R=/data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta BAIT_INTERVALS=../../../intervals/baits.interval_list TARGET_INTERVALS=../../../intervals/targets.interval_list

	java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar CollectAlignmentSummaryMetrics I=${i} O=${NAME}_aln_metrics.txt R=/data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta
	}
	
export -f foo8

for i in *BQSR.bam
do
sem -j 32 --id QC_hs foo8 "$i"
done
sem --wait --id QC_hs
	
