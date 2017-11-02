#!/bin/bash
rg_dir=`echo 2_skewer`
mkdir -p "$rg_dir"

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

mv *trimmed* ./2_skewer

cd ./2_skewer

mkdir -p "$rg_dir"

cd /data2/patrick/Patients/DNA/Exome/processed/2_skewer/test/5
foo () {
local i=$1
	OUTPUT_DIR=`echo ./3_bwamem`	
	SAMPLE=`echo $i | sed 's/\([A-Za-z0-9_]*\)-trimmed-pair1.fastq.gz/\1/'`;
	
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

foo4 () {
local i=$1
	NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_sorted_dedup_fixmate.bam/\1/'`;
	/data/Phil/software/GATK4B5/gatk-launch --javaOptions "-Xmx64G" BaseRecalibrator -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -L ../../../../intervals/targets.interval_list --interval_padding 100 --knownSites /data/Phil/ref_phil/GATK_resource/b37/dbsnp_138.b37.vcf.gz  --knownSites /data/Phil/ref_phil/GATK_resource/b37/Mills_and_1000G_gold_standard.indels.b37.vcf.gz --knownSites /data/Phil/ref_phil/GATK_resource/b37/1000G_phase3_v4_20130502.sites.vcf.gz -O ${NAME}_recal_data.table
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
	/data/Phil/software/GATK4B5/gatk-launch --javaOptions "-Xmx64G" ApplyBQSR -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -L ../../../../intervals/targets.interval_list --interval_padding 100 -bqsr ${NAME}_recal_data.table -O ${NAME}_BQSR.bam 

}
export -f foo5
for i in *sorted_dedup_fixmate.bam
do
sem -j 16 --id bqsr2 foo5 "$i"
done
sem --wait --id bqsr2

# Next, GatherBQSRReports? There's no documentation yet. 


foo8 () {
local i=$1
NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_BQSR.bam/\1/'`;
	java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar CollectHsMetrics I=${i} O=${NAME}_hs_metrics.txt  R=/data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta BAIT_INTERVALS=../../../intervals/baits.interval_list TARGET_INTERVALS=../../../intervals/targets.interval_list

	java -Xmx16G -jar /data/Phil/software/picard-tools-2.9.0/picard.jar CollectAlignmentSummaryMetrics I=${i} O=${NAME}_aln_metrics.txt R=/data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta
	}
	
export -f foo8

for i in *BQSR.bam
do
sem -j 32 --id QC_hs foo8 "$i"
done
sem --wait --id QC_hs
	

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

mv *pcr_metrics.txt ../QC_reports_b37
mv *aln_metrics.txt ../QC_reports_b37
mv *hs_metrics.txt ../QC_reports_b37
