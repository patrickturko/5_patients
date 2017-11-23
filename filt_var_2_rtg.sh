#!/bin/bash

#Only need to do this once: create a SDG file from the human reference. 
# rtg format -o /data2/patrick/reference/b37.SDF /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta

source activate patrick

cd ../DNA/Exome/processed/7_variants
mkdir ../8_final_calls

find . -maxdepth 1 -mindepth 1 -type d > patient_names.txt

foo15(){
	local NAME=$1
	local strelka=${NAME}/all_callers/${NAME}_strelka_tumor.vcf.gz
	local varscan=${NAME}/all_callers/${NAME}_varscan_tumor.vcf.gz
	local mutect2=${NAME}/all_callers/${NAME}_mutect2_tumor.vcf.gz
	
	rm -R ${NAME}/comparisons
	mkdir ${NAME}/comparisons
	

	rtg vcfeval --squash-ploidy -b ${strelka} -c ${varscan} -t /data2/patrick/reference/b37.SDF -f DP \
	-o ${NAME}/comparisons/strelka_varscan

	rtg vcfeval --squash-ploidy -b ${mutect2} -c ${strelka} -t /data2/patrick/reference/b37.SDF -f DP \
	-o ${NAME}/comparisons/strelka_mutect2

	rtg vcfeval --squash-ploidy -b ${mutect2} -c ${varscan} -t /data2/patrick/reference/b37.SDF -f DP \
	-o ${NAME}/comparisons/varscan_mutect2

	
}

export -f foo15

for word in $(cat patient_names.txt)
do
sem -j 16 --id rtg foo15 $word
done
sem --wait --id rtg

foo16(){
	local NAME=$1
	local sv=${NAME}/comparisons/strelka_varscan/tp.vcf.gz
	local sm=${NAME}/comparisons/strelka_mutect2/tp.vcf.gz
	local vm=${NAME}/comparisons/varscan_mutect2/tp.vcf.gz

	bcftools concat -a -O v -D ${sv} ${sm} ${vm} | vcf-sort | bgzip > ../8_final_calls/${NAME}_consensus.vcf.gz
	tabix ../8_final_calls/${NAME}_consensus.vcf.gz

}

export -f foo16

for word in $(cat patient_names.txt)
do
sem -j 16 --id consensus foo16 $word
done
sem --wait --id consensus





