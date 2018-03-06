#!/bin/bash -e

#get time series for each subj within region

module load python/3.6_ciftify_01
module load connectome-workbench/1.2.3

#calc time series per region
HCP_DIR=/projects/edickie/analysis/POND_RST/hcp
cd $HCP_DIR
SUBJECTS=`ls -1d MR160*`

TSOUTDIR=/scratch/nforde/homotopic/POND/hcp/glasser_meants
#mkdir $TSOUTDIR

for SUBJECT in $SUBJECTS; do
  echo $SUBJECT
  ciftify_meants \
        --outputcsv ${TSOUTDIR}/${SUBJECT}_RST_pond42fix_glasser_meants.csv \
        --outputlabels ${TSOUTDIR}/${SUBJECT}_RST_pond42fix_glasser_roiids.csv \
        ${SUBJECT}/MNINonLinear/Results/RST_pond42fix/RST_pond42fix_Atlas_s8.dtseries.nii \
        /scratch/nforde/homotopic/atlases/HCP_Glasser_210_CorticalAreas.32k_fs_LR.dlabel.nii

done
