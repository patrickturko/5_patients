#!/bin/bash

cd /data2/patrick/Patients/DNA/Exome/processed/2_skewer/test/5




foo5 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	/data/Phil/software/GATK4B5/gatk-launch --javaOptions "-Xmx64G" ApplyBQSR -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -L ../../../../intervals/targets.interval_list --interval_padding 100 -bqsr ${NAME}_recal_data.table -O ${NAME}_BQSR.bam 

}
export -f foo5
for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id bqsr2 foo5 "$i"
done
sem --wait --id bqsr2

# Next, GatherBQSRReports? There's no documentation yet. 

