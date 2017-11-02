#!/bin/bash

cd ../DNA/Exome/processed/2_skewer/test/6

foo9 () {
	local i=$1	
	local NAME=`cat $i | sed 's/.*\([Pp]atient_[[:digit:]].\)BQSR.bam/\1/'`;
	local PATIENT=`cat $i | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`;
	mkdir ${PATIENT}/pileups
	samtools mpileup -b ${i} -l ../../../../intervals/S07604624_Covered.bed -v -o ${NAME}_pileup.vcf

	mv *pileup.vcf ${PATIENT}/pileups
	}

export -f foo9
for i in *BQSR.bam
do
echo $i > temp.txt
sem -j 16 --id mpileup foo9 temp.txt
done
sem --wait --id mpileup



