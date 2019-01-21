#!/usr/bin/

#--------------------------------------------------------------------------------
## convert tck to trk file type
source /projects/nforde/mypython/bin/activate


for subj in 'P102' 'P104' 'P107' 'P109' 'P113' 'P116' 'P119' 'P120' 'P121' 'P122' 'P124' 'P125' 'P126'; do
  cd /scratch/zmcdonald/TMS_fMRI/$subj/MRtrix_Outputs
  #using FA mask as ref
  # can add -f flag to force overwrite
  python /scratch/nforde/homotopic/bin/tck2trk.py $subj\_b0bet_eddy.nii.gz $subj\_tracks.tck
  cd ../
done

deactivate
