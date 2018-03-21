#!/usr/bin/

module load FSL/5.0.9

#--------------------------------------------------------------------------------

cd /sctatch/nforde/homotopic/POND/CSD
SUBJECTS=`ls -1d MR160*`

for subj in $SUBJECTS; do
  cd $subj

  fslmaths gmwmi.nii.gz -bin gmwmi_bin.nii.gz
  fslstats -K glasser.nii.gz gmwmi_bin.nii.gz -V > voxel_count.txt

done 
