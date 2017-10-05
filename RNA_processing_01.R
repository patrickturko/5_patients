#RNAseq analysis for cell lines
#setwd("/scratch/che")
setwd("/data/Phil/ref_phil/GTF")
library(data.table)
library(parallel)
library(ggvis)
library(rtracklayer)

###making shared memory bigger for STAR
#orginal settings for shmall and shmmax
#kernel.shmall = 268435456
#kernel.shmmax = 4294967295

#sysctl -A | grep shm
#sysctl -w kernel.shmall=12582912
#sysctl -w kernel.shmmax=94489280512
#reset kernal for normal use
#sysctl -p

###preparing gtf file for annotation in linux command line
#awk '/protein_coding/ {print $0;}' gencode.v27.annotation.gtf > protein_coding_v27.txt

#awk -F"\t"  '{split($9,a,";"); for (i=1;i<=length(a);i++) if (a[i]~/gene_id/) { split(a[i],b,"\"");x=b[2] } else if (a[i]~/gene_name/) {split(a[i],c,"\"");y=c[2]}; print $1,$4,$5,x,y}' OFS="\t" protein_coding_v27.txt > ensembl_gene_v27.txt

gene.name <- fread("/data/Phil/ref_phil/GTF/ensembl_gene_v27.txt", header=F)
gene.name <- unique(gene.name)
setkey(gene.name, V4)

gene.name2 <- readGFF("/data/Phil/ref_phil/GTF/gencode.v27.annotation.gtf", tags = c("gene_id", "gene_name", "transcript_id", "transcript_name"))
entrez <- fread("/data/Phil/ref_phil/GTF/gencode.v27.metadata.EntrezGene")

gene.name3 <- data.table(gene.name2)
setkey(gene.name3, type)
gene.name5 <- merge(gene.name3, entrez, by.x = "transcript_id", by.y = "V1")
setkey(gene.name5, type)
gene.name5["gene"]

setkey(gene.name5, gene_id)


library(org.Hs.eg.db)
keys <- head(keys(org.Hs.eg.db), n=2)
cols <- c("ENTREZID", "SYMBOL")
entrez2 <- select(org.Hs.eg.db, gene.name$V5, cols, keytype="SYMBOL")

#collecting names of all samples into one table for easy use
setwd("/data2/patrick/Patients/RNA")
samples <- data.table(dir(pattern = "_R1"))
setnames(samples, "fastq")
samples[, sample_name := sub(".*[0-9]*.A-(.*)_R1.*", "\\1", samples$fastq)]

write.table(samples, "160518_sample_annotation_celllines.txt", sep="\t", row.names=F) #edit with excel to include treatment


#import count tables and start differential analysis
setwd("/data2/Phil/RNAseq/Cell_lines/FASTQ_second_round/skewer/align/RNA_counts/")
dDir <- ("/data2/Phil/RNAseq/Cell_lines/FASTQ_second_round/skewer/align/RNA_counts/")

f <- dir(pattern=("ReadsPerGene"))
f.name <- sub("(.*?)_ReadsPerGene.*", "\\1", f)
names(f) <- f.name

pfs1 <- lapply(f, function(u) {
  cat("Reading",u,"\n")
  fread( file.path(dDir,u))
}) #reads every file in f and imports it into list, with name of f, comment charcter is turned off

save(pfs1,file="160518_RNAseq_STAR_count_cell_lines.Rdata") #saves list of normalized data


