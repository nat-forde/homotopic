###using Shen atlas instead #meants will needs to be available with correct parcellation (epi-meants needs to run)

library(igraph)
library(dplyr)
library(tidyr)
library(ggplot2)
library(broom)
library(knitr)
library(car)
library(neurobase)
library(proxy)

setwd("/mnt/tigrlab/scratch/nforde/homotopic/bin")

## set all the paths
#aparc_labels_clut <- "aparc_labels.txt"
shen_labels_clut <- "Shen_labels_150.txt"
pond_demographics <- read.csv("/projects/stephanie/DataFiles_CT.DTI.Beh.POND/GlimExtIN_CTROIUF.csv")
qap_functional_temporal <- read.csv("qap_functional_temporal.csv")
tsdir <- "/projects/edickie/analysis/POND_RST/hcp/aparc_meants"
ts_pattern <- "RST_pond42fix"


#make df of every roi to every other
make_g_template <- function(subid, tsdir, ts_pattern) {
  meants <- read.csv(file.path(tsdir,
                               paste(subid, ts_pattern, "Atlas_s8_shen150_meants.csv", sep="_")),
                     header=FALSE)  
  ROIs <- character()
  for (i in 1:278) {
    ROIs[[length(ROIs)+1]] <- paste("roi", i, sep = "")
  }
  meants_t <- t(meants)
  colnames(meants_t) <- ROIs
  
  cormat <- cor(meants_t)
  g<-graph_from_adjacency_matrix(cormat,mode="upper", 
                                 weighted=T, diag=F, 
                                 add.rownames = "code")
  g.df <- as.data.frame(get.edgelist(g), names=T)
  
  ## load atlas, convert to df, flip a copy and isolate 1 hemi of orig and flip to use Dice on
  shen_atlas <- readnii("/scratch/nforde/POND/atlases/Shen_atlas_150_2mm.nii")
  shen_df <- neurobase::img_color_df(shen_atlas)
  shen_df_1hemi <- subset(shen_df, dim1 >= 45)
  
  shen_flipped <- neurobase::flip_img(shen_atlas, x=TRUE, y=FALSE, z=FALSE)
  #neurobase::double_ortho(shen_atlas, shen_flipped) #to check the flip
  shen_flip_df <- neurobase::img_color_df(shen_flipped)
  shen_flip_df_1hemi <- subset(shen_flip_df, dim1 >= 45)
  
  ## separate each roi into its own variable
  orig_roi_df <- data.frame(matrix("NA", ncol = 0, nrow = length(shen_df_1hemi$value)))  
  for (i in 1:278) {
    roi <- numeric(length(shen_df_1hemi$value))
    roi[shen_df_1hemi$value == i] <- 1 
    orig_roi_df <- cbind(orig_roi_df, roi)
  }
  
  flip_roi_df <- data.frame(matrix("NA", ncol = 0, nrow = length(shen_flip_df_1hemi$value)))  
  for (i in 1:278) {
    roi <- numeric(length(shen_flip_df_1hemi$value))
    roi[shen_flip_df_1hemi$value == i] <- 1 
    flip_roi_df <- cbind(flip_roi_df, roi)
  }
  
  #rename columns
  colnames(orig_roi_df) <- ROIs #orig = left
  colnames(flip_roi_df) <- ROIs #flipped = right
  
  right_vars <- paste("roi", 1:139, sep="")
  right_roi_df <- flip_roi_df[right_vars]
  left_vars <- paste("roi", 140:278, sep="")
  left_roi_df <- orig_roi_df[left_vars]
  roi_df <- cbind(right_roi_df, left_roi_df)
  
  ##dice/jaccard
  jac_df <- data.frame(matrix("0", ncol = length(names(right_roi_df)), nrow = length(names(left_roi_df))))
  colnames(jac_df) <- right_vars
  rownames(jac_df) <- left_vars
  cols = c(1:length(names(jac_df)))   
  jac_df[,cols] = apply(jac_df[,cols], 2, function(x) as.numeric(as.character(x)))
  
  for (r in 1:139) {
    for (l in 140:278) {
      m <- roi_df[[paste("roi", r, sep = "")]] + roi_df[[paste("roi", l, sep = "")]]
      common <- sum(m == 2)
      unique <- sum(m == 1)
      j <- common/(common+unique)
      jac_df[paste("roi", l, sep = ""), paste("roi", r, sep = "")] <-j
    }
  }  
  
  g.df$V1.hemi <- NA
  g.df$V2.hemi <- NA
  g.df$V1.hemi[g.df$V1<140] <- "R"
  g.df$V1.hemi[g.df$V1>139] <- "L"
  g.df$V2.hemi[g.df$V2<140] <- "R"
  g.df$V2.hemi[g.df$V2>139] <- "L"
  
  #find highest overlap for each roi and assign as homotopic
  r_homo <- max.col(jac_df)
  l_homo <- c(140:278)
  homox <-as.data.frame(cbind(l_homo, r_homo))
  homo <- rbind(homox, setNames(rev(homox), names(homox)))
  homo$FCtype <- "Homotopic"
  
  g.df <- merge(g.df, homo, by.x=c("V1","V2"),by.y=c("l_homo","r_homo"), all.x=TRUE)

  g.df$FCtype[g.df$V1.hemi==g.df$V2.hemi] <- "Intrahemispheric"
  g.df$FCtype[g.df$V1.hemi!=g.df$V2.hemi & is.na(g.df$FCtype)] <- "Heterotopic"  
  
  return(g.df)
  
}