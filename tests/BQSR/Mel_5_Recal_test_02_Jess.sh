#!/bin/bash

cd ../../../DNA/Exome/processed/2_skewer/test/

foo5 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	java -Xmx16G -jar /data/Phil/software/GATK_3.7/GenomeAnalysisTK.jar -T BaseRecalibrator -R /data/Phil/ref_phil/GATK_resource/hg19/ucsc.hg19.fasta -I ${i} -knownSites /data/Phil/ref_phil/GATK_resource/hg19/dbsnp_138.hg19.vcf.gz  -knownSites /data/Phil/ref_phil/GATK_resource/hg19/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz -knownSites /data/Phil/ref_phil/GATK_resource/hg19/1000G_phase1.snps.high_confidence.hg19.sites.vcf.gz -L chr20 -BQSR ${NAME}_recal_data.table -o ${NAME}_post_recal_data.table 

}
export -f foo5
for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id bqsr2 foo5 "$i"
done
sem --wait --id bqsr2

