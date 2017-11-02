#!/bin/bash

cd ../DNA/Exome/processed/2_skewer/test/6

foo11 () {
	local i=$1
	local NAME=`echo $i | sed 's/\([A-Za-z0-9_]*\)_BQSR.bam/\1/'`
	local PATIENT=`echo $i | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	mkdir ${PATIENT}/haplotypecaller
	
	/data/Phil/software/GATK4B5/gatk-launch --javaOptions "-Xmx8G" HaplotypeCaller -R /data/Phil/ref_phil/GATK_resource/b37/human_g1k_v37.fasta -I ${i} -L ../../../../intervals/targets.interval_list --interval_padding 100 --dbsnp /data/Phil/ref_phil/GATK_resource/b37/dbsnp_138.b37.vcf.gz -O ${NAME}_haplo.g.vcf

	mv ${NAME}_haplo.g.vcf ${PATIENT}/haplotypecaller

}

export -f foo11

for i in *BQSR.bam
do
sem -j 16 --id haplo foo11 "$i"
done
sem --wait --id haplo
