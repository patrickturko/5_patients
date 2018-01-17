biocLite("ensemblVEP")
library(ensemblVEP)
library(VariantAnnotation)
library(data.table)

# Had to create ~/.Renvironment file to update PATH

vepdata <- "/home/wid/.vep"


#set parameters for VEP
param <- VEPParam(basic = basicOpts(version = 90, verbose = TRUE,
                    input = inputOpts(assembly = "GRCh37")),
                  cache = cacheOpts(version = 90, cache = T,
                                    dir = vepdata,
                                    dir_cache = vepdata,
                                    offline = TRUE,
                                    database = databaseOpts(database = FALSE,
                                          host = "ensembldb.ensembl.org")),
                  identifier = identifierOpts(version = 90, hgvs = TRUE,
                                              symbol = TRUE,
                                              protein = TRUE,
                                              canonical = TRUE,
                                              tsl = TRUE,
                                              biotype = TRUE),
                  output = outputOpts(version = 90, variant_class = TRUE,
                                      sift = "b",
                                      polyphen = "b",
                                      regulartory = TRUE,
                                      total_length =TRUE,
                                      numbers = TRUE,
                                      domains = TRUE)
                  )

#make into function
v2m <- function(f2){
  g2 <- ensemblVEP(f2)
  library(data.table)
  vcf <- readVcf(f2, "GRCh37")
  #filter for canonical genes, so only 1 trascript for gene
  filt <- !is.na(g2$CANONICAL)
  
  #extract chr names or contig location
  chrnames <- as.character(seqnames(g2)[filt])
  
  #Variant classification and type
  cons <- fread("vep_consequences.txt")
  setnames(cons, make.names(colnames(cons))
  
  #only take first match from VEP output
  var_class <- sapply(strsplit(g2$Consequence, "&"), "[[", 1)
  setkey(cons, SO.term )
  
  #subset vcf by only genes annotated by VEP
  vcf2 <- vcf[match(names(g2)[filt], names(vcf))]
  
  #get distances of snps to determine if SNP or INS or DEL
  we <- width(granges(vcf2)$REF)
  wa <- width(unlist(granges(vcf2)$ALT))
  var_type <- ifelse((wa == 1) & (wa == we), "SNP", ifelse(wa == we, "ONP", ifelse(we < wa, "INS", "DEL")))
  table(var_type)
  
  #Get Tumor and Sample name from VCF
  name_norm <- "NORM"
  name_tumor <- "TUMOR"
  
  #Create MAF file
  test <- data.table(Hugo_Symbol = g2$SYMBOL[filt],
                     Entrez_Gene_Id = g2$HGNC_ID[filt],
                     Center = "Zurich",
                     NCBI_Build = "b37",
                     Chromosome = chrnames,
                     Start_position = start(g2)[filt],
                     End_position = end(g2)[filt],
                     Strand = g2$STRAND[filt],
                     Variant_Classification = cons[var_class[filt], MAF_Variant_Classification],
                     Variant_Type = var_type,
                     Reference_Allele = as.character(granges(vcf2)$REF),
                     Tumor_Seq_Allele1 = as.character(granges(vcf2)$REF),
                     Tumor_Seq_Allele2 = as.character(unlist(granges(vcf2)$ALT)),
                     dbSNP_RS = replace(names(vcf2), grepl("[[:punct:]]", names(vcf2)),""),
                     dnSNP_Val_Status = "NA",
                     Tumor_Sample_Barcode = name_tumor,
                     Matched_Norm_Sample_Barcode = name_norm,
                     Match_Norm_Seq_Allele1 = "",
                     Match_Norm_Seq_Allele2 = "",
                     Tumor_Validation_Allele1 = "",
                     Tumor_Validation_Allele2 = "",
                     Match_Norm_Validation_Allele1 = "",
                     Match_Norm_Validation_Allele2 = "",
                     Verification_Status = "",
                     Validation_Status = "",
                     Mutation_Status = "Somatic",
                     Sequencing_Phase = "",
                     Sequence_Source = "WXS",
                     Validation_Method = "",
                     Score = "",
                     Sequence_Source = "",
                     BAM_File = "",
                     Sequencer = "Illumina HiSeq 2500",
                     Tumor_Sample_UUID = name_tumor,
                     Matched_Norm_Sample_UUID = name_norm,
                     HGVS =  g2$HGVSc[filt],
                     t_depth = rowSums(matrix(unlist(geno(vcf2)$AD[, "TUMOR"]), ncol = 2, byrow = TRUE)),
                     t_ref_count = matrix(unlist(geno(vcf2)$AD[, "TUMOR"]), ncol = 2, byrow = TRUE)[,1],
                     t_alt_count = matrix(unlist(geno(vcf2)$AD[, "TUMOR"]), ncol = 2, byrow = TRUE)[,2],
                     n_depth = rowSums(matrix(unlist(geno(vcf2)$AD[, "NORMAL"]), ncol = 2, byrow = TRUE)),
                     n_ref_count = matrix(unlist(geno(vcf2)$AD[, "NORMAL"]), ncol = 2, byrow = TRUE)[,1],
                     n_alt_count = matrix(unlist(geno(vcf2)$AD[, "NORMAL"]), ncol = 2, byrow = TRUE)[,2],
                     predicted_damage = g2$IMPACT[filt],
                     accession = g2$Gene[filt],
                     AA_Change = g2$HGVSp[filt],
                     Tumor_Type = "",
                     median_tumor_rnaseq = "",
                     median_normal_rnaseq = "",
                     median_tumor_nimblegen = "",
                     median_normal_nimblegen = "",
                     phylopConsScore = "",
                     phastCons = "",
                     PolyPhen = g2$PolyPhen[filt],
                     SIFT = g2$SIFT[filt],
                     pfam_domain = g2$DOMAINS[filt],
                     go_terms = "",
                     COSMIC = "",
                     strand = g2$STRAND[filt],
                     mRNA_position = g2$cDNA_position[filt],
                     left_seq = "",
                     right_seq = "",
                     var_nucleotide = paste0(as.character(granges(vcf2)$REF), "/", as.character(unlist(granges(vcf2)$ALT))) ,
                     protein_accession = g2$ENSP[filt],
                     variant_allele_freq = geno(vcf2)$AF[, "TUMOR"],
                     Reads = "",
                     consequences = g2$Consequence[filt],
                     protein_position = g2$Protein_position[filt],
                     FILTER = fixed(vcf2)$FILTER,
                     fisher_exact_p_value_of_tumor_and_normal_read_counts = "",
                     allelefilter = "",
                     allelefilterresult = ""
                     )
  
  test
  
}



f3 <- dir(path = "/data2/patrick/Patients/DNA/Exome/processed/7_final_calls/", 
          pattern = "*.vcf.gz$")

f2 <- "/data2/patrick/Patients/DNA/Exome/processed/7_variants/Patient_5/all_callers/Patient_5_mutect2_filtered.vcf.gz"

dDir <- "/data2/patrick/Patients/DNA/Exome/processed/8_final_calls/"
f2 <- paste0(dDir, f3[1])


muts <- lapply(paste0(dDir, f3), v2m)

muts.all <- Reduce(rbind, muts)

fwrite(muts.all, "171218_Melarray_fourth.txt", sep = "\t")
