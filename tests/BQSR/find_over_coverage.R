setwd("/data2/patrick/Patients/DNA/Exome/processed/2_skewer/test/4")
library(ggplot2)
library(reshape2)
library(data.table)

#Load coverage stats
coverage <- fread("_coverage_stats")
#Load intervals 
intervals <- fread("_coverage_stats.sample_interval_summary")

#Format intervals
intervals <- intervals[, "Target"]
intervals[, c("chr", "start", "end") := tstrsplit(Target, "[:-]")]
intervals[, start := as.integer(start)]
intervals[, end := as.integer(end)]
intervals <- intervals[, -"Target"]
setkey(intervals, chr, start, end)

#Choose which loci to investigate and format data.table
bads <- coverage[Total_Depth > 500, ]
bads[, c("chr", "start"):= tstrsplit(Locus, ":")]
bads[, end:= as.numeric(start) +1]

bad_intervals <- paste(bads$chr, bads$start, bads$end, sep = "\t")
write.table(bad_intervals, "bad_intervals.bed", quote = F, row.names = F, 
            col.names = F)

# bedtools merge -d 1 -i bad_intervals.bed > test.bed