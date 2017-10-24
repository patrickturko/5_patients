setwd("/data2/patrick/Patients/DNA/Exome/processed/2_skewer/test/4")
library(ggplot2)
library(reshape2)
library(data.table)
#Load coverage stats
coverage <- fread("_coverage_stats")

#subset how you like
rows <- runif(50000, 1, nrow(coverage))
lil_cov <- coverage[rows, ]
lil_cov <- coverage[Total_Depth > 400,]


#Separate chromorsome and position data
lil_cov[, c("chr", "pos") := tstrsplit(Locus, ":")]

#Plot
by_locus <- ggplot(lil_cov, aes(x = pos, y = Total_Depth))+
  geom_line(aes(group = 1)) +
  facet_wrap( ~ chr, scales = "free") +
  theme_bw() +
  theme(axis.text.x = element_blank(),
        axis.ticks.x = element_blank()) +
  theme(aspect.ratio = 1) 
by_locus

ggsave("coverage_by_locus.png", by_locus, device = "png", height = 8, width = 8, units = "in")
