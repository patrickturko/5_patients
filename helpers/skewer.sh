#!/bin/bash

foo () {
local i=$1
	OUTPUT_DIR=`echo ./2_skewer`
	SAMPLE=`echo $i | sed 's/\(.*\)_R1.fastq.gz/\1/'`;
	NAME=`echo $i | sed 's/[0-9]*.A-\([A-Za-z0-9_]*\)_[A-Z]*_R[1-2].fastq.gz/\1/'`;
	#echo ${i}
	#echo ${SAMPLE}_R2.fastq.gz
	#echo ${NAME}_R2.fastq.gz
	skewer -t 32 -m pe -q 20 -z ${i} ${SAMPLE}_R2.fastq.gz -o ${NAME}
}

export -f foo

for i in *R1.fastq.gz
do 
sem -j 1 foo "$i" --id skewer
done
sem --wait --id skewer

