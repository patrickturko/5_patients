#!/bin/bash


cd ../DNA/Exome/processed/6_bqsr_b37/patient_3
find *blood*BQSR.bam | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/' > patient_names.txt
foo8 () {
	local tumor=$1
	local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	echo ${NAME}-mutect2
	
	TUMORNAME=`samtools view -H ${tumor} | grep '^@RG' | sed "s/.*SM:\([^\t]*\).*/\1/g" | uniq`
	NORMALNAME=`samtools view -H ${normal} | grep '^@RG' | sed "s/.*SM:\([^\t]*\).*/\1/g" | uniq`
	
	/data/Phil/software/GATK4B5/gatk-launch --javaOptions "-Xmx8G" Mutect2 -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${tumor} -tumor ${TUMORNAME} -I ${normal} -normal ${NORMALNAME} -L ../../../intervals/targets.interval_list --interval_padding 100 --dbsnp /data/Phil/ref_phil/GATK_resource/b37/dbsnp_138.b37.vcf.gz --germline_resource /data/Phil/ref_phil/GATK_resource/b37/1000G_phase3_v4_20130502.sites.vcf.gz -O ${NAME}_mutect2.vcf.gz

	

}
export -f foo8

for word in $(cat patient_names.txt)
do
sem -j 16 --id mutect2 foo8 *$word*tumor*BQSR.bam *$word*blood*BQSR.bam
done
sem --wait --id mutect2
