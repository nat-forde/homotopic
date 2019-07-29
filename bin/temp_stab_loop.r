

trios <- filter(demogs, scanner== "trio") %>% .$subid
prismas <- filter(demogs, scanner== "prisma") %>% .$subid



for (s in 1:length(trios)) {
  meants.file <- file.path(tsdir, trios[s], "DK_meants.csv")
  if (file.exists(meants.file)) {
    stab.file <- file.path(tsdir, trios[s], "DK_60sec_tempstab.csv")
    if (file.exists(stab.file)) {
      ts.df <- read.csv(stab.file) 
    } else {
      #print("no stab file")
      ts.df <- calc_subject_stability(trios[s], tsdir, g.df, 26)
      write.csv(ts.df, stab.file, row.names = F)
    }
  }
}


for (s in 1:length(prismas)) {
  meants.file <- file.path(tsdir, prismas[s], "DK_meants.csv")
  if (file.exists(meants.file)) {
    stab.file <- file.path(tsdir, prismas[s], "DK_60sec_tempstab.csv")
    if (file.exists(stab.file)) {
      ts.df <- read.csv(stab.file) 
    } else {
      #print("no stab file")
      ts.df <- calc_subject_stability(prismas[s], tsdir, g.df, 40)
      write.csv(ts.df, stab.file, row.names = F)
    }
  }
}