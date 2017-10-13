#!/bin/bash

cd ../../../DNA/Exome/processed/2_skewer/test/4/

foo4 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	echo ${NAME}
	java -Xmx16G -jar /data/Phil/software/GATK_3.8/GenomeAnalysisTK.jar -T BaseRecalibrator -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -knownSites /data/Phil/ref_phil/GATK_resource/b37/dbsnp_138.b37.vcf.gz  -knownSites /data/Phil/ref_phil/GATK_resource/b37/Mills_and_1000G_gold_standard.indels.b37.vcf.gz -knownSites /data/Phil/ref_phil/GATK_resource/b37/1000G_phase3_v4_20130502.sites.vcf.gz -L 20 -o ${NAME}_recal_data.table 
}
export -f foo4

for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id bqsr1 foo4 "$i"
done
sem --wait --id bqsr1

