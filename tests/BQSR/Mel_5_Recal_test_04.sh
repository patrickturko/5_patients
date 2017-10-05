#!/bin/bash

cd ../../../DNA/Exome/processed/2_skewer/test/

foo7 () {
local i=$1
	OUTPUT_DIR=`echo GATK_BQSR/`
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	java -Xmx32G -jar /data/Phil/software/GATK_3.7/GenomeAnalysisTK.jar -T PrintReads -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -BQSR ${NAME}_recal_data.table -o ${NAME}_sorted_dedup_fixmate_bqsr.bam 
}
export -f foo7
for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id bqsr4 foo7 "$i"
done
sem --wait --id bqsr4


