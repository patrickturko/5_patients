#!/bin/bash


cd ../DNA/Exome/processed/2_skewer/test/6

ls *blood*BQSR.bam | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/' > patient_names.txt

foo7 () {
local tumor=$1
local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`;
	echo ${NAME}
	mkdir ${NAME}/strelka
	
	python /data/Phil/software/strelka/configureStrelkaSomaticWorkflow.py --normalBam ${normal} --tumorBam ${tumor} --referenceFasta /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta --indelCandidates ${NAME}/manta/results/variants/candidateSmallIndels.vcf.gz --runDir $PWD --exome --callRegions ../../../../intervals/S07604624_Covered.bed.gz;

	python runWorkflow.py -m local -j 8;
	mkdir ${NAME}/strelka/python
	mv *[Ww]orkflow* ${NAME}/strelka/python
	mv results ${NAME}/strelka
	mv workspace ${NAME}/strelka

}
export -f foo7

for word in $(cat patient_names.txt)
do
sem -j 16 --id strelka foo7 *$word*tumor*BQSR.bam *$word*blood*BQSR.bam;
done
sem --wait --id strelka

