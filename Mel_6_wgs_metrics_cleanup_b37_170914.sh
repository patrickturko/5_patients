#!/bin/bash


rg_dir5=`echo QC_reports_b37`
mkdir -p "$rg_dir5"

foo8 () {
local i=$1
NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate_bqsr.bam/\1/'`;
	java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar CollectWgsMetrics I=${i} O=${NAME}_wgs_metrics.txt  R=/data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta

	java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar CollectAlignmentSummaryMetrics I=${i} O=${NAME}_aln_metrics.txt R=/data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta
	}
	
export -f foo8

for i in *sorted_dedup_fixmate_bqsr.bam
do
sem -j 32 --id QC foo8 "$i"
done
sem --wait --id QC
	
mv *sorted.bam 3_bwamem_b37
mv *sorted.bai 3_bwamem_b37

mv *metrics.txt 4_dedup_b37
mv *sorted_dedup.bam 4_dedup_b37

mv *sorted_dedup_fixmate.bam 5_fixmate_b37
mv *sorted_dedup_fixmate.bai 5_fixmate_b37

mv *.table 6_bqsr_b37
mv *plots.pdf 6_bqsr_b37
mv *sorted_dedup_fixmate_bqsr.bam 6_bqsr_b37
mv *sorted_dedup_fixmate_bqsr.bai 6_bqsr_b37

mv *pcr_metrics.txt QC_reports_b37
mv *aln_metrics.txt QC_reports_b37
mv *hs_metrics.txt QC_reports_b37
