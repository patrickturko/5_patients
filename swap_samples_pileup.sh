#!/bin/bash


	NAME=`echo *.vcf | sed 's/.*\([Pp]atient_[[:digit:]]\).*/\1/'`
	bcftools view -h *.vcf > old_head.txt
	NORMAL=`awk '/^#CHROM/{print $11}' old_head.txt` 
	TUMOR=`awk '/^#CHROM/{print $10}' old_head.txt` 
	sed "s/$NORMAL/\n/g; s/$TUMOR/$NORMAL/g; s/\n/$TUMOR/g" old_head.txt > new_head.txt
	
	bcftools view -H *.vcf | awk '{t = $10; $10 = $11; $11 = t; print; }' >> new_head.txt
	mv new_head.txt ${NAME}_pileup_rearranged.vcf

