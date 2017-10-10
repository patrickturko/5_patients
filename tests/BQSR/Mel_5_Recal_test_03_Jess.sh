#!/bin/bash

cd ../../../DNA/Exome/processed/2_skewer/test/

foo6 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	java -Xmx16G -jar /data/Phil/software/GATK_3.7/GenomeAnalysisTK.jar -T AnalyzeCovariates -R /data/Phil/ref_phil/GATK_resource/hg19/ucsc.hg19.fasta -before ${NAME}_recal_data.table -after ${NAME}_post_recal_data.table -plots ${NAME}_recalibration_plots.pdf
}
export -f foo6
for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id bqsr3 foo6 "$i" 
done
sem --wait --id bqsr3

