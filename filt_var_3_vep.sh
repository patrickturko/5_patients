#!/bin/bash


cd ../DNA/Exome/processed/8_final_calls
#mkdir ../9_annotated_calls

find . *.vcf.gz > patient_names.txt

foo17(){
	local NAME=$1
	local PATIENT=`echo ${NAME} | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`

	vep -i $NAME -o ${PATIENT}_annotated.txt --cache --offline --everything -fork 16 --force_overwrite
	
}

export -f foo17

for word in $(cat patient_names.txt)
do
sem -j 16 --id vep foo17 $word
done
sem --wait --id vep

mv *annotated* ../9_annotated_calls

