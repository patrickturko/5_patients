#!/bin/bash


cd ../DNA/Exome/processed/2_skewer/6_bqsr_b37/

find *blood*BQSR.bam | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/' > patient_names.txt

rg_dir5=`echo 7_variants_b37`
mkdir -p "$rg_dir5"

foo6 () {
local tumor=$1
local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	echo ${NAME}
	mkdir ${NAME}
	mkdir ${NAME}/manta
	python /data/Phil/software/manta/configManta.py --normalBam ${normal} --tumorBam ${tumor} --referenceFasta /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta --exome --callRegions ../../../../intervals/S07604624_Covered.bed.gz --runDir $PWD;
	
	python runWorkflow.py -m local -j 8
	mkdir ${NAME}/manta/python
	mv *[Ww]orkflow* ${NAME}/manta/python
	mv results ${NAME}/manta
	mv workspace ${NAME}/manta

}
export -f foo6

for word in $(cat patient_names.txt)
do
sem -j 16 --id manta foo6 *$word*tumor*BQSR.bam *$word*blood*BQSR.bam
done
sem --wait --id manta


foo7 () {
local tumor=$1
local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	echo ${NAME}
	mkdir ${NAME}/strelka
	
	python /data/Phil/software/strelka/configureStrelkaSomaticWorkflow.py --normalBam ${normal} --tumorBam ${tumor} --referenceFasta /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta --indelCandidates ${NAME}/manta/results/variants/candidateSmallIndels.vcf.gz --runDir $PWD --exome --callRegions ../../../../intervals/S07604624_Covered.bed.gz

	python runWorkflow.py -m local -j 8

	cd results/variants/
	for filename in *; do mv "$filename" "${NAME}_strelka_$filename";  done
	cd ../..

	mkdir ${NAME}/strelka/python
	mv *[Ww]orkflow* ${NAME}/strelka/python
	mv results ${NAME}/strelka
	mv workspace ${NAME}/strelka

}
export -f foo7

for word in $(cat patient_names.txt)
do
sem -j 16 --id strelka foo7 *$word*tumor*BQSR.bam *$word*blood*BQSR.bam
done
sem --wait --id strelka


foo8 () {
	local tumor=$1
	local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	echo ${NAME}
	mkdir ${NAME}/mutect2_GATK4
	TUMORNAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]_tumor_DNA\).*/\1/'`
	NORMALNAME=`echo ${normal} | sed 's/.*\([Pp]atient_[[:digit:]]_blood_DNA\).*/\1/'`
	
	/data/Phil/software/GATK4B5/gatk-launch --javaOptions "-Xmx8G" Mutect2 -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${tumor} -tumor ${TUMORNAME} -I ${normal} -normal ${NORMALNAME} -L ../../../../intervals/targets.interval_list --interval_padding 100 --dbsnp /data/Phil/ref_phil/GATK_resource/b37/dbsnp_138.b37.vcf.gz --germline_resource /data/Phil/ref_phil/GATK_resource/b37/1000G_phase3_v4_20130502.sites.vcf.gz -O ${NAME}_mutect2.vcf.gz

	mv ${NAME}_mutect2.vcf.gz ${NAME}/mutect2_GATK4

}
export -f foo8

for word in $(cat patient_names.txt)
do
sem -j 16 --id mutect2 foo8 *$word*tumor*BQSR.bam *$word*blood*BQSR.bam
done
sem --wait --id mutect2

foo9 () {
	local i=$1
	local NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_BQSR.bam/\1/'`
	local PATIENT=`echo $i | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	mkdir ${PATIENT}/pileups
	samtools mpileup -f /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -l ../../../../intervals/S07604624_Covered.bed -v --output ${NAME}_pileup.vcf ${i}
	mv *pileup.vcf ${PATIENT}/pileups

	}

export -f foo9

for i in *BQSR.bam
do
sem -j 16 --id mpileup foo9 "$i"
done
sem --wait --id mpileup

foo10() {
local tumor=$1
local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	java -Xmx16G -jar /data/Phil/software/VarScan.v2.4.2.jar somatic ${normal} ${tumor} ${NAME} --output-vcf 1

	# What file does Varscan emit? Make a directory and move it there. 
}
	
export -f foo10

for word in $(cat patient_names.txt)
do
sem -j 16 --id varscan foo10 $word/pileups/*$word*tumor*pileup.vcf $word/pileups/*$word*blood*pileup.vcf 
done
sem --wait --id varscan

foo11 () {
	local i=$1
	local NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_BQSR.bam/\1/'`
	local PATIENT=`echo $i | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	mkdir ${PATIENT}/haplotypecaller
	
	/data/Phil/software/GATK4B5/gatk-launch --javaOptions "-Xmx8G" HaplotypeCaller -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -L ../../../../intervals/targets.interval_list --interval_padding 100 --dbsnp /data/Phil/ref_phil/GATK_resource/b37/dbsnp_138.b37.vcf.gz -O ${NAME}_haplo.g.vcf

	mv ${NAME}_haplo.g.vcf ${PATIENT}/haplotypecaller

}

export -f foo11

for i in *BQSR.bam
do
sem -j 16 --id haplo foo11 "$i"
done
sem --wait --id haplo

