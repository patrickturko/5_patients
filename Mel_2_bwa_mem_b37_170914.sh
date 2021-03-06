#!/bin/bash
rg_dir=`echo 3_bwamem_b37`
mkdir -p "$rg_dir"

foo () {
local i=$1
	OUTPUT_DIR=`echo ./3_bwamem`
	#OUTPUT_DIR2=`echo ./GATK_RNA_dedup/`
	
	SAMPLE=`echo $i | sed 's/\([A-Za-z0-9_]*\)-trimmed-pair1.fastq.gz/\1/'`;
	#NAME=`echo $i | sed 's/[0-9]*.[A-Z]-\([A-Za-z0-9-]*\)_R1.fastq-trimmed-pair1.fastq.gz/\1/'`;
	#dir = `echo pwd`
	#echo ${SAMPLE}
	#echo $NAME
	#echo ${i}
	#echo ./${SAMPLE}_R1.fastq-trimmed-pair2.fastq.gz
	bwa mem -t 32 -M -R "@RG\tID:Melanoma\tLB:Melarray\tSM:${SAMPLE}\tPL:ILLUMINA\tPU:HiSEQ4000" /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta ./${i} ./${SAMPLE}-trimmed-pair2.fastq.gz | java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar SortSam I=/dev/stdin O=${SAMPLE}_sorted.bam  CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT SO=coordinate
}
export -f foo

for i in *-trimmed-pair1.fastq.gz
do
sem -j 1 --id bwa foo "$i"
done
sem --wait --id bwa
