#process FASTQ
setwd("/data2/patrick/Patients/RNA/2_skewer")
library(data.table)
library(parallel)

fq <- list.files(pattern = "trimmed-pair1", recursive = FALSE)
samples <- data.table(file_name = fq, sample_name = fq)

#make reference genome with STAR no splice junctions
#system(paste("STAR --runThreadN 32 --runMode genomeGenerate --genomeDir /data/Phil/ref_phil/STAR_index/ --genomeFastaFiles /data/Phil/ref_phil/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna --sjdbGTFfile /data/Phil/ref_phil/GTF/gencode.v22.annotation.gtf"))

#alignment using STAR

#read from skewer fastq

setwd("/data2/Phil/RNAseq/Jessica/Fastq/")

samples[, fastq_skewer := list.files(pattern="trimmed.fastq.gz")]



#first pass to build new junction file

lapply(seq(1:nrow(samples)), function(x) system(paste0("STAR --readFilesCommand zcat --readFilesIn ", samples$file_name[x], " --genomeLoad LoadAndKeep --genomeDir /data/Phil/ref_phil/GRCh38/STAR_index_GRCh38 --runThreadN 32 --outFileNamePrefix ",  samples$file_name[x], "_")))



#merge all junction files together for 2nd pass mapping

system(paste0("cat *SJ.out.tab > all.SJ.out.tab"))



#make new genome index with new junctions

system(paste("STAR --limitBAMsortRAM 80000000000 --runThreadN 32 --runMode genomeGenerate --genomeDir /data/Phil/ref_phil/GRCh38/STAR_index_GRCh38 --genomeFastaFiles /data/Phil/ref_phil/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna --sjdbGTFfile /data/Phil/ref_phil/GTF/gencode.v27.annotation.gtf --sjdbFileChrStartEnd all.SJ.out.tab"))
#here now


#remove genome from memory

system(paste("STAR --limitBAMsortRAM 80000000000 --genomeLoad Remove --genomeDir /data/Phil/ref_phil/GRCh38/STAR_index_GRCh38 --runThreadN 32"))



#remap to new genome with new junctions

lapply(seq(1:nrow(samples)), function(x) system(paste("STAR --limitBAMsortRAM 80000000000 --readFilesCommand zcat --readFilesIn", samples$fastq_skewer[x], "--genomeLoad LoadAndKeep --genomeDir /data/Phil/ref_phil/GRCh38/STAR_index_GRCh38 --runThreadN 32 --outSAMtype BAM SortedByCoordinate --quantMode TranscriptomeSAM GeneCounts --outFileNamePrefix",  paste0("./align/",samples$sample_name[x],"."), sep=" ")))



#remove genome from memory

system(paste("STAR --limitBAMsortRAM 80000000000 --genomeLoad Remove --genomeDir /data/Phil/ref_phil/GRCh38/STAR_index_GRCh38 --runThreadN 32"))



#import count tables and start differential analysis





f <- dir(path = "align", pattern=("ReadsPerGene"))

dDir <- "align"

f.name <- sub("(.*?)\\..*", "\\1", f)

names(f) <- f.name



pfs1 <- lapply(f, function(u) {
  
  cat("Reading",u,"\n")
  
  fread( file.path(dDir,u))
  
}) #reads every file in f and imports it into list, with name of f, comment charcter is turned off

save(pfs1, file = "170505_Jessica_RNAseq.RData")

write.table(samples, "170505_Jessica_samples.txt", sep = "\t", row.names = FALSE)