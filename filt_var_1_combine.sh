#!/bin/bash

cd ../DNA/Exome/processed/7_variants
find . -maxdepth 1 -mindepth 1 -type d > patient_names.txt

foo12 () {
	local i=$1
	local NAME=$2
	mkdir ${NAME}/all_callers
	
	/data/Phil/software/GATK4B5/gatk-launch --javaOptions "-Xmx4G" FilterMutectCalls \
   	-V ${i} \
	-L ../../intervals/targets.interval_list --interval_padding 100 -O ${NAME}/all_callers/${NAME}_mutect2_filtered.vcf.gz
	tabix -f ${NAME}/all_callers/${NAME}_mutect2_filtered.vcf.gz
}
export -f foo12

for word in $(cat patient_names.txt)
do
sem -j 16 --id filt_mutect foo12 $word/mutect2/*.vcf.gz $word
done
sem --wait --id filt_mutect

foo13 () {
	local indels=$1
	local snvs=$2
	local NAME=$3
	
	vcf-concat ${indels} ${snvs} | vcf-sort | bgzip > ${NAME}/all_callers/${NAME}_strelka.vcf.gz
	tabix ${NAME}/all_callers/${NAME}_strelka.vcf.gz

}
export -f foo13

for word in $(cat patient_names.txt)
do
sem -j 16 --id comb_strel foo13 $word/strelka/results/variants/*indels.vcf.gz $word/strelka/results/variants/*snvs.vcf.gz $word
done
sem --wait --id comb_strel

foo14 () {
	local indels=$1
	local snvs=$2
	local NAME=$3
	#| vcf-sort -c -p 10 | bgzip 
	vcf-concat ${indels} ${snvs} | vcf-sort | bgzip > ${NAME}/all_callers/${NAME}_varscan.vcf.gz
	tabix ${NAME}/all_callers/${NAME}_varscan.vcf.gz

}
export -f foo14

for word in $(cat patient_names.txt)
do
sem -j 16 --id comb_varsc foo14 $word/varscan/*indel* $word/varscan/*snp* $word
done
sem --wait --id comb_varsc
