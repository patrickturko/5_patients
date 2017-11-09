#!/bin/bash


cd ../DNA/Exome/processed/6_bqsr_b37/

#find *blood*BQSR.bam | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/' > patient_names.txt
#mkdir `cat patient_names.txt`

#for word in $(cat patient_names.txt)
#do
#mv *$word*BQSR.ba* $word
#done


foo7 () {
local tumor=$1
local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	echo ${NAME}-strelka
	mkdir ${NAME}/strelka
	
	python /data/Phil/software/strelka/configureStrelkaSomaticWorkflow.py --normalBam ${normal} --tumorBam ${tumor} --referenceFasta /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta --runDir ${NAME} --exome --callRegions ../../intervals/S07604624_Covered.bed.gz

	python ${NAME}/runWorkflow.py -m local -j 8

	mkdir ${NAME}/strelka/python
	mv ${NAME}/*[Ww]orkflow* ${NAME}/strelka/python
	mv ${NAME}/results ${NAME}/strelka
	mv ${NAME}/workspace ${NAME}/strelka

}
export -f foo7

for word in $(cat patient_names.txt)
do
sem -j 16 --id strelka foo7 $word/*$word*tumor*BQSR.bam $word/*$word*blood*BQSR.bam
done
sem --wait --id strelka

foo8 () {
	local tumor=$1
	local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	echo ${NAME}-mutect2
	mkdir ${NAME}/mutect2_GATK4
	TUMORNAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]_tumor_DNA\).*/\1/'`
	NORMALNAME=`echo ${normal} | sed 's/.*\([Pp]atient_[[:digit:]]_blood_DNA\).*/\1/'`
	
	/data/Phil/software/GATK4B5/gatk-launch --javaOptions "-Xmx8G" Mutect2 -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${tumor} -tumor ${TUMORNAME} -I ${normal} -normal ${NORMALNAME} -L ../../intervals/targets.interval_list --interval_padding 100 --dbsnp /data/Phil/ref_phil/GATK_resource/b37/dbsnp_138.b37.vcf.gz --germline_resource /data/Phil/ref_phil/GATK_resource/b37/1000G_phase3_v4_20130502.sites.vcf.gz -O ${NAME}_mutect2.vcf.gz

	mv ${NAME}_mutect2.vcf.gz ${NAME}/mutect2_GATK4

}
export -f foo8

for word in $(cat patient_names.txt)
do
sem -j 16 --id mutect2 foo8 $word/*$word*tumor*BQSR.bam $word/*$word*blood*BQSR.bam
done
sem --wait --id mutect2

foo9 () {
local tumor=$1
local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	echo ${NAME}-pileups
	mkdir ${NAME}
	mkdir ${NAME}/pileups
	samtools mpileup -f /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -l ../../intervals/S07604624_Covered.bed -v --output ${NAME}_pileup.vcf ${tumor} ${normal};

	mv ${NAME}_pileup.vcf ${NAME}/pileups

	}

export -f foo9

for word in $(cat patient_names.txt)
do
sem -j 16 --id pileup foo9 $word/*$word*tumor*BQSR.bam $word/*$word*blood*BQSR.bam
done
sem --wait --id pileup


foo10() {
local i=$1
	NAME=`echo ${i} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	echo $NAME-varscan
	java -Xmx16G -jar /data/Phil/software/VarScan.v2.4.2.jar somatic ${i} ${NAME} --output-vcf 1 --mpileup 1

	# What file does Varscan emit? Make a directory and move it there. 
	# This section hasn't been tested, do it individually with call_var_5_varscan.sh
}
	
export -f foo10

for word in $(cat patient_names.txt)
do
sem -j 16 --id varscan foo10 $word/pileups/*pileup.vcf 
done
sem --wait --id varscan
