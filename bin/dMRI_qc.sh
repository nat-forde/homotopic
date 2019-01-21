#!bin/bash -l

module load FSL/6.0
# generate qc files for diffusion data using fsl's quad and squad

cd /projects/nforde/POND/dtifit

SUBJECTS=`ls -d sub-*`
for subj in $(</scratch/nforde/homotopic/bin/dtifit_doagain.txt); do
  cd /projects/nforde/POND/dtifit/$subj
  eddy_quad data -idx index.txt -par acqparams.txt -m nodif_brain_mask.nii.gz -b dwi.bval

done


for subj in $(</scratch/nforde/homotopic/bin/single.txt); do
  echo /projects/nforde/POND/dtifit/$subj/data.qc
done > /scratch/nforde/homotopic/bin/dwiQCsingle.txt

cd /projects/nforde/POND/dtifit
eddy_squad /scratch/nforde/homotopic/bin/dwiQCsingle.txt


for subj in $(</scratch/nforde/homotopic/bin/multi.txt); do
  echo /projects/nforde/POND/dtifit/$subj/data.qc
done > /scratch/nforde/homotopic/bin/dwiQCmulti.txt

cd /projects/nforde/POND/dtifit
eddy_squad /scratch/nforde/homotopic/bin/dwiQCmulti.txt
