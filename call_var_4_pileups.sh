#!/bin/bash

cd ../DNA/Exome/processed/2_skewer/test/6
ls *blood*BQSR.bam | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/' > patient_names.txt

foo9 () {
	local i=$1
	local NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_BQSR.bam/\1/'`
	local PATIENT=`echo $i | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	mkdir ${PATIENT}/pileups
	samtools mpileup -f /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -l ../../../../intervals/S07604624_Covered.bed -v --output ${NAME}_pileup.vcf ${i};
	mv *pileup.vcf ${PATIENT}/pileups

	}

export -f foo9

for i in *BQSR.bam
do
sem -j 16 --id mpileup foo9 "$i"
done
sem --wait --id mpileup

