#!/bin/bash


cd ../DNA/Exome/processed/2_skewer/test/6

ls *blood*BQSR.bam | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/' > patient_names.txt

foo8 () {
	local tumor=$1;
	local normal=$2;
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`;
	echo ${NAME};
	mkdir ${NAME}/mutect2_GATK4;
	TUMORNAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]_tumor_DNA\).*/\1/'`;
	NORMALNAME=`echo ${normal} | sed 's/.*\([Pp]atient_[[:digit:]]_blood_DNA\).*/\1/'`;
	
	/data/Phil/software/GATK4B5/gatk-launch --javaOptions "-Xmx8G" Mutect2 -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${tumor} -tumor ${TUMORNAME} -I ${normal} -normal ${NORMALNAME} -L ../../../../intervals/targets.interval_list --interval_padding 100 --dbsnp /data/Phil/ref_phil/GATK_resource/b37/dbsnp_138.b37.vcf.gz --germline_resource /data/Phil/ref_phil/GATK_resource/b37/1000G_phase3_v4_20130502.sites.vcf.gz -O ${NAME}_variants_mutect2.vcf.gz;

	mv ${NAME}_variants_mutect2.vcf.gz ${NAME}/mutect2_GATK4;

}
export -f foo8

for word in $(cat patient_names.txt)
do
sem -j 16 --id mutect2 foo8 *$word*tumor*BQSR.bam *$word*blood*BQSR.bam;
done
sem --wait --id mutect2

