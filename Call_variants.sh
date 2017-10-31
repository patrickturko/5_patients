#!/bin/bash

cd ../DNA/Exome/processed/2_skewer/

ls *blood*BQSR.bam | sed 's/\([Pp]atient_[[:digit:]]\).*/\1/' > patient_names.txt

rg_dir5=`echo 7_variants_b37`
mkdir -p "$rg_dir5"

foo6 () {
local tumor=$1
local normal=$2
local analysis_path=$3
	NAME=`echo tumor | sed 's/\([A-Za-z0-9_]*\)_BQSR.bam/\1/'`;
	echo ${NAME}
	/data/Phil/software/manta/bin/configManta.py --normalBam ${normal} --tumorBam ${tumor} --referenceFasta /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta --runDir ${pathway};

	${analysis_path}/runWorkflow.py -m local -j 16	


}
export -f foo4

for word in $(cat test.txt)
do
sem -j 16 --id manta foo6 ls *$word*tumor*BQSR.bam ls *$word*blood*BQSR.bam
done
sem --wait --id manta




rg_dir7=`echo MuTect2`
mkdir -p "$rg_dir7"

array=(`awk -F'\t' '{if (NR!=1) {print$2}}' Melarray_mutect2_tumor_normal.txt`)

foo10 () {
local i=$1
array=(`awk -F'\t' '{if (NR!=1) {print$2}}' Melarray_mutect2_tumor_normal.txt`)
array2=(`awk -F'\t' '{if (NR!=1) {print$3}}' Melarray_mutect2_tumor_normal.txt`)
#printf "%s is in %s\n" "${array[i]}" "${array2[i]}"
t1=`echo ${array[i]} | sed 's/\([A-Za-z0-9-]*\)\r/\1/'`
n1=`echo ${array2[i]} | sed 's/\([A-Za-z0-9-]*\)\r/\1/'`
mkdir ${t1}_${n1}
java -Xmx16G -jar /data/Phil/software/GATK_3.6/GenomeAnalysisTK.jar -T MuTect2 -R /data/Phil/ref_phil/GATK_resource/hg19/ucsc.hg19.fasta -I:tumor ${t1}_sorted_dedup_fixmate_bqsr.bam -I:normal ${n1}_sorted_dedup_fixmate_bqsr.bam -o MuTect2/${t1}_${n1}/${t1}_mutect2.vcf --dbsnp /data/Phil/ref_phil/GATK_resource/hg19/dbsnp_138.hg19.vcf.gz --cosmic /data/Phil/ref_phil/GATK_resource/hg19/CosmicCodingMuts_chr_M_sorted.vcf.gz -L 151127_out.bed
}
export -f foo10

for ((i=0;i<${#array[@]};++i))
do
sem --id mutect2 -j 20 foo10 "$i"
done
sem --wait --id mutect2

