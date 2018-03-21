#!/usr/bin/

#--------------------------------------------------------------------------------
## convert tck to trk file type
source /projects/nforde/mypython/bin/activate

cd /scratch/nforde/homotopic/POND/CSD/
SUBJECTS=`ls -1d *`

for subj in $SUBJECTS; do
  cd $subj
  #using FA mask as ref
  # can add -f flag to force overwrite
  python /scratch/nforde/homotopic/bin/tck2trk.py FAmask.nii.gz tracks.tck
  cd ../
done

deactivate
