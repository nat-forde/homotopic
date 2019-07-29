#! /opt/quarantine/R/3.4.3/build2/bin/Rscript

args <- commandArgs(TRUE)

if (length(args)==0) {
  stop("At least one argument must be supplied (subj_ID).n", call.=FALSE)
} else if (length(args)==1) {
  # default window size is 30 secs
  args[2] = 13 #trio tr=2.34ms 13~30sec, 26~60sec. prisma tr=1.5ms 20~30sec, 40~60sec
}

subid = args[1]
window_size = args[2]

library("zoo", lib.loc="/scratch/nforde/homotopic/bin/R_lib")
library("forecast", lib.loc="/scratch/nforde/homotopic/bin/R_lib")

## set all the paths
tsdir <- "/projects/nforde/POND/rsMRI"
#ts_pattern <- "RST_pond42fix"
g.df <- read.csv("g.df.DK.csv", header=TRUE) #this is in the homotopic/bin for the different atlases

meants.file <- file.path(tsdir, subid, "DK_meants.csv")
meants <- read.csv(meants.file, header = F)

roiids <- read.csv(file.path(tsdir, subid, "DK_roiids.csv"), header=FALSE)
rois <- as.character(roiids$V1)

meants_t <- as.data.frame(t(meants))
names(meants_t) <- rois
sub.df <- g.df[ ,c("V1","V2")]
sub.df$Stability <- NA
for (i in 1:nrow(sub.df)) {
  meants_t2 <- meants_t[,c(as.character(sub.df$V1[i]),as.character(sub.df$V2[i]))]
  if (sum(colSums(is.na(meants_t2))) == 0) {
    z <- rollapply(meants_t2,
                   window_size,
                   function(x) cor(x[,1],x[,2], use = "na.or.complete"),
                   by.column=FALSE)
    sub.df$Stability[i] <- mean(Acf(z)$acf)
  }
}

#stab.file <- file.path(tsdir, subid, paste(subid, "glasser", window_size, "tempstab.csv", sep="_"))
stab.file <- file.path(tsdir, subid, "DK_30sec_tempstab.csv")
write.csv(sub.df, stab.file, row.names = F)
