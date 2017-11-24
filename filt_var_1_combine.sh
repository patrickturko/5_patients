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

	/data/Phil/software/GATK4B5/gatk-launch --javaOptions "-Xmx4G" SelectVariants \
	-R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta \
	-V ${i} -se 'tumor' --excludeFiltered -O ${NAME}/all_callers/${NAME}_mutect2_tumor.vcf

	bcftools view ${NAME}/all_callers/${NAME}_mutect2_tumor.vcf | vcf-sort | bgzip > ${NAME}/all_callers/${NAME}_mutect2_tumor.vcf.gz
	tabix ${NAME}/all_callers/${NAME}_mutect2_tumor.vcf.gz -f
	
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
	
	
	bcftools concat ${indels} ${snvs} -O v -a | vcf-sort | awk '{if(/^##/) print; else if(/^#/) print "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n"$0; else print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\tGT:"$9"\t1/1:"$10"\t1/1:"$11;}' | bgzip > ${NAME}/all_callers/${NAME}_strelka.vcf.gz
	tabix ${NAME}/all_callers/${NAME}_strelka.vcf.gz
	bcftools view -s TUMOR -f .,PASS ${NAME}/all_callers/${NAME}_strelka.vcf.gz | vcf-sort | bgzip > ${NAME}/all_callers/${NAME}_strelka_tumor.vcf.gz
	tabix ${NAME}/all_callers/${NAME}_strelka_tumor.vcf.gz -f
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
	tabix ${indels}; tabix ${snvs};

	bcftools concat ${indels} ${snvs} -O v -a | vcf-sort | bgzip > ${NAME}/all_callers/${NAME}_varscan.vcf.gz
	tabix ${NAME}/all_callers/${NAME}_varscan.vcf.gz
	bcftools view -s TUMOR -f .,PASS ${NAME}/all_callers/${NAME}_varscan.vcf.gz | vcf-sort | bgzip > ${NAME}/all_callers/${NAME}_varscan_tumor.vcf.gz
	tabix ${NAME}/all_callers/${NAME}_varscan_tumor.vcf.gz -f
}
export -f foo14

for word in $(cat patient_names.txt)
do
sem -j 16 --id comb_varsc foo14 $word/varscan/*indel*vcf.gz $word/varscan/*snp*vcf.gz $word
done
sem --wait --id comb_varsc
