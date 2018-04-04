#! /opt/quarantine/R/3.4.3/build2/bin/Rscript

args <- commandArgs(TRUE)

if (length(args)==0) {
  stop("At least one argument must be supplied (subj_ID).n", call.=FALSE)
} else if (length(args)==1) {
  # default window size is 30
  args[2] = 30
}

subid = args[1]
window_size = args[2]

library("zoo", lib.loc="/scratch/nforde/homotopic/bin/R_lib")
library("lmtest", lib.loc="/scratch/nforde/homotopic/bin/R_lib")
library("forecast", lib.loc="/scratch/nforde/homotopic/bin/R_lib")

## set all the paths
tsdir <- "/scratch/nforde/homotopic/POND/hcp/glasser_meants"
ts_pattern <- "RST_pond42fix"
g.df <- read.csv("g.df.csv", header=TRUE)

meants.file <- file.path(tsdir,
                         paste(subid, ts_pattern, "glasser_meants.csv", sep="_"))
meants <- read.csv(meants.file, header = F)

roiids <- read.csv(file.path(tsdir,
                             paste(subid, ts_pattern, "glasser_roiids.csv", sep="_")),
                   header=TRUE) 

rois <- as.character(roiids$labelname)
meants_t <- as.data.frame(t(meants))
names(meants_t) <- rois  
sub.df <- g.df[ ,c("V1","V2")]
sub.df$Stability <- NA
for (i in 1:nrow(sub.df)) {
  z <- rollapply(meants_t[,c(sub.df$V1[i],sub.df$V2[i])], 
                 as.numeric(window_size),
                 function(x) cor(x[,1],x[,2]), 
                 by.column=FALSE)
  sub.df$Stability[i] <- mean(Acf(z)$acf)
}

stab.file <- file.path(tsdir, paste(subid, ts_pattern, "glasser", window_size, "tempstab.csv", sep="_"))
write.csv(sub.df, stab.file, row.names = F)
