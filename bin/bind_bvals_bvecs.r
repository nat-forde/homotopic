#! /opt/quarantine/R/3.4.3/build2/bin/Rscript

args <- commandArgs(TRUE)

if (length(args)==0) {
  stop("At least one argument must be supplied (subj_ID).n", call.=FALSE)
}

subid = args[1]
B1 = args[2]
B2 = args[3]
B3 = args[4]

##
C1 <- read.table(B1)
C2 <- read.table(B2)
C3 <- read.table(B3)

B <- cbind(C1, C2, C3)

if (length(B$V1)==3) {
  write.table(B, paste("/projects/nforde/POND/dwi", subid, "dwi.bvec", sep="/"), sep=" ", col.names=FALSE, row.names=FALSE)
} else if (length(B$V1)==1){
  write.table(B, paste("/projects/nforde/POND/dwi", subid, "dwi.bval", sep="/"), sep=" ", col.names=FALSE, row.names=FALSE)
}
