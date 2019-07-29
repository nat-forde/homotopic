#!/usr/bin/env bash
#
# create residuals from spherical harmonic fit on the already processed dwi data

subj=$1

#for raw concatenated data
cd /KIMEL/tigrlab/projects/nforde/POND/dtifit/$subj
rm denoise2.nii.gz residualSH.nii.gz
dwidenoise -noise residualSH.nii.gz data.nii.gz denoise2.nii.gz
rm denoise2.nii.gz
fslmaths residualSH.nii.gz -mas nodif_brain_mask.nii.gz residualSH_masked.nii.gz

cd ..
