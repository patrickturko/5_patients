#!/bin/bash


rg_dir4=`echo 6_bqsr_b37`
mkdir -p "$rg_dir4"

foo4 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	echo ${NAME}
	java -Xmx64G -jar /data/Phil/software/GATK_3.7/GenomeAnalysisTK.jar -T BaseRecalibrator -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -knownSites /data/Phil/ref_phil/GATK_resource/b37/dbsnp_138.b37.vcf.gz  -knownSites /data/Phil/ref_phil/GATK_resource/b37/Mills_and_1000G_gold_standard.indels.b37.vcf.gz -knownSites /data/Phil/ref_phil/GATK_resource/b37/1000G_phase3_v4_20130502.sites.vcf.gz -L ../DNA/Exome/intervals/targets.interval_list --interval_padding 100 -o ${NAME}_recal_data.table 
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
	java -Xmx64G -jar /data/Phil/software/GATK_3.7/GenomeAnalysisTK.jar -T BaseRecalibrator -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -knownSites /data/Phil/ref_phil/GATK_resource/b37/dbsnp_138.b37.vcf.gz  -knownSites /data/Phil/ref_phil/GATK_resource/b37/Mills_and_1000G_gold_standard.indels.b37.vcf.gz -knownSites /data/Phil/ref_phil/GATK_resource/b37/1000G_phase3_v4_20130502.sites.vcf.gz -L ../DNA/Exome/intervals/targets.interval_list --interval_padding 100 -BQSR ${NAME}_recal_data.table -o ${NAME}_post_recal_data.table 

}
export -f foo5
for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id bqsr2 foo5 "$i"
done
sem --wait --id bqsr2

foo6 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	java -Xmx64G -jar /data/Phil/software/GATK_3.7/GenomeAnalysisTK.jar -T AnalyzeCovariates -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -before ${NAME}_recal_data.table -after ${NAME}_post_recal_data.table -plots ${NAME}_recalibration_plots.pdf
}
export -f foo6
for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id bqsr3 foo6 "$i" 
done
sem --wait --id bqsr3


