#!/bin/bash

cd /data2/patrick/Patients/DNA/Exome/processed/2_skewer/test/5

foo4 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	/data/Phil/software/GATK4B5/gatk-launch --javaOptions "-Xmx64G" BaseRecalibrator -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -L ../../../../intervals/targets.interval_list --interval_padding 100 --knownSites /data/Phil/ref_phil/GATK_resource/b37/dbsnp_138.b37.vcf.gz  --knownSites /data/Phil/ref_phil/GATK_resource/b37/Mills_and_1000G_gold_standard.indels.b37.vcf.gz --knownSites /data/Phil/ref_phil/GATK_resource/b37/1000G_phase3_v4_20130502.sites.vcf.gz -O ${NAME}_recal_data.table
	}
export -f foo4
for i in *sorted_dedup_fixmate.bam
do 
sem -j 16 --id bqsr1 foo4 "$i"
done
sem --wait --id bqsr1


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

