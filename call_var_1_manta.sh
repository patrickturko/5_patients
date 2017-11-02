#!/bin/bash


cd ../DNA/Exome/processed/2_skewer/6_bqsr_b37/

find *blood*BQSR.bam | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/' > patient_names.txt

rg_dir5=`echo 7_variants_b37`
mkdir -p "$rg_dir5"

foo6 () {
local tumor=$1
local normal=$2
	NAME=`echo ${tumor} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`;
	echo ${NAME}
	mkdir ${NAME}
	mkdir ${NAME}/manta
	python /data/Phil/software/manta/configManta.py --normalBam ${normal} --tumorBam ${tumor} --referenceFasta /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta --exome --callRegions ../../../../intervals/S07604624_Covered.bed.gz --runDir $PWD;
	
	python runWorkflow.py -m local -j 8;
	mkdir ${NAME}/manta/python
	mv *[Ww]orkflow* ${NAME}/manta/python
	mv results ${NAME}/manta
	mv workspace ${NAME}/manta

}
export -f foo6

for word in $(cat patient_names.txt)
do
sem -j 16 --id manta foo6 *$word*tumor*BQSR.bam *$word*blood*BQSR.bam;
done
sem --wait --id manta

