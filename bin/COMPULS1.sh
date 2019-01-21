#!/bin/bash -l

module load FSL/5.0.10 dcm2niix/v1.0.20181125

cd /projects/nforde/COMPULS
SUBJECTS=`ls -d 10*`
# SUBJECTS=`ls -d 65*`
for subj in $SUBJECTS; do
  dcm2niix -i y $subj
  cd $subj
  


done
