#!/bin/bash

cd ../../../DNA/Exome/processed/2_skewer/test/

foo4 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	echo ${NAME}
	java -Xmx16G -jar /data/Phil/software/GATK_3.7/GenomeAnalysisTK.jar -T BaseRecalibrator -R /data/Phil/ref_phil/GATK_resource/hg19/ucsc.hg19.fasta -I ${i} -knownSites /data/Phil/ref_phil/GATK_resource/hg19/dbsnp_138.hg19.vcf.gz  -knownSites /data/Phil/ref_phil/GATK_resource/hg19/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz -knownSites /data/Phil/ref_phil/GATK_resource/hg19/1000G_phase1.snps.high_confidence.hg19.sites.vcf.gz -L chr20 -o ${NAME}_recal_data.table  
}
export -f foo4

for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id bqsr1 foo4 "$i"
done
sem --wait --id bqsr1

