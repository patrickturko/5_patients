#!/bin/bash


cd ../DNA/Exome/processed/6_bqsr_b37



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
