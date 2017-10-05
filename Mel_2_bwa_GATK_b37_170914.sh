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

rg_dir2=`echo 4_dedup_b37`
mkdir -p "$rg_dir2"

foo2 () {
local i=$1
	#OUTPUT_DIR=`echo 4_dedup/`
	#OUTPUT_DIR2=`echo ./GATK_RNA_dedup/`
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted.bam/\1/'`;
	echo ${NAME}
	java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar MarkDuplicates I=${i} O=${NAME}_sorted_dedup.bam  M=${NAME}_metrics.txt
}
export -f foo2

for i in *sorted.bam
do
sem -j 16 --id dedup foo2 "$i"
done
sem --wait --id dedup

rg_dir3=`echo 5_fixmate_b37`
mkdir -p "$rg_dir3"

foo3 () {
local i=$1
	OUTPUT_DIR=`echo ./5_fixmate/`
	#OUTPUT_DIR2=`echo ./GATK_RNA_dedup/`
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup.bam/\1/'`;
	echo ${NAME}
	java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar FixMateInformation VALIDATION_STRINGENCY=SILENT CREATE_INDEX=true SORT_ORDER=coordinate I=${i} O=${NAME}_sorted_dedup_fixmate.bam 
}
export -f foo3
for i in *sorted_dedup.bam
do
sem -j 16 --id fixmate foo3 "$i"
done
sem --wait --id fixmate

rg_dir4=`echo 6_bqsr_b37`
mkdir -p "$rg_dir4"

foo4 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	echo ${NAME}
	java -Xmx16G -jar /data/Phil/software/GATK_3.7/GenomeAnalysisTK.jar -T BaseRecalibrator -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -knownSites /data/Phil/ref_phil/GATK_resource/b37/dbsnp_138.b37.vcf.gz  -knownSites /data/Phil/ref_phil/GATK_resource/b37/Mills_and_1000G_gold_standard.indels.b37.vcf.gz -knownSites /data/Phil/ref_phil/GATK_resource/b37/1000G_phase3_v4_20130502.sites.vcf.gz -o ${NAME}_recal_data.table 
}
export -f foo4

for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id bqsr1 foo4 "$i"
done
sem --wait --id bqsr1

foo5 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	java -Xmx16G -jar /data/Phil/software/GATK_3.7/GenomeAnalysisTK.jar -T BaseRecalibrator -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -knownSites /data/Phil/ref_phil/GATK_resource/b37/dbsnp_138.b37.vcf.gz  -knownSites /data/Phil/ref_phil/GATK_resource/b37/Mills_and_1000G_gold_standard.indels.b37.vcf.gz -knownSites /data/Phil/ref_phil/GATK_resource/b37/1000G_phase3_v4_20130502.sites.vcf.gz -BQSR ${NAME}_recal_data.table -o ${NAME}_post_recal_data.table 

}
export -f foo5
for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id bqsr2 foo5 "$i"
done
sem --wait --id bqsr2

foo6 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	java -Xmx16G -jar /data/Phil/software/GATK_3.7/GenomeAnalysisTK.jar -T AnalyzeCovariates -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -before ${NAME}_recal_data.table -after ${NAME}_post_recal_data.table -plots ${NAME}_recalibration_plots.pdf
}
export -f foo6
for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id bqsr3 foo6 "$i" 
done
sem --wait --id bqsr3

foo7 () {
local i=$1
	OUTPUT_DIR=`echo GATK_BQSR/`
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	java -Xmx16G -jar /data/Phil/software/GATK_3.7/GenomeAnalysisTK.jar -T PrintReads -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -BQSR ${NAME}_recal_data.table -o ${NAME}_sorted_dedup_fixmate_bqsr.bam 
}
export -f foo7
for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id bqsr4 foo7 "$i"
done
sem --wait --id bqsr4

rg_dir5=`echo QC_reports_b37`
mkdir -p "$rg_dir5"

foo8 () {
local i=$1
NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate_bqsr.bam/\1/'`;
	java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar CollectWgsMetrics I=${i} O=${NAME}_wgs_metrics.txt  R=/data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta

	java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar CollectAlignmentSummaryMetrics I=${i} O=${NAME}_aln_metrics.txt R=/data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta
	}
	
export -f foo8

for i in *sorted_dedup_fixmate_bqsr.bam
do
sem -j 32 --id QC foo8 "$i"
done
sem --wait --id QC
	
mv *sorted.bam 3_bwamem_b37
mv *sorted.bai 3_bwamem_b37

mv *metrics.txt 4_dedup_b37
mv *sorted_dedup.bam 4_dedup_b37

mv *sorted_dedup_fixmate.bam 5_fixmate_b37
mv *sorted_dedup_fixmate.bai 5_fixmate_b37

mv *.table 6_bqsr_b37
mv *plots.pdf 6_bqsr_b37
mv *sorted_dedup_fixmate_bqsr.bam 6_bqsr_b37
mv *sorted_dedup_fixmate_bqsr.bai 6_bqsr_b37

mv *pcr_metrics.txt QC_reports_b37
mv *aln_metrics.txt QC_reports_b37
mv *hs_metrics.txt QC_reports_b37
