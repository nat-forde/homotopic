#!/bin/bash -e

module load SGE-extras/1.0
export RSTUDIO_PANDOC=/mnt/tigrlab/quarantine/rstudio/1.1.414/build/rstudio-1.1.414/bin/pandoc

sge_batch bash script.sh
sge_batch -k -o mylog.log Rscript -e 'rmarkdown::render("temporal_stability_calc_glasser.Rmd")'
