#!/usr/bin/env bash

module load FSL/5.0.10

## mk fieldmaps
cd /external/pond/data/
SUBJECTS=`ls -d sub-*`

for subj in $SUBJECTS; do
	if [[ -d "/external/pond/data/$subj/ses-01/fmap" ]]; then
    inDir=/external/pond/data/$subj/ses-01/fmap
    if [[ ! -d "/projects/nforde/POND/fmap/$subj" ]]; then
      cd /projects/nforde/POND/fmap/
      mkdir $subj
    fi
    tmpdir=/projects/nforde/POND/fmap/$subj/tmp
    mkdir $tmpdir

    cd $tmpdir

    # bet $inDir/$subj\_ses-01_magnitude1.nii.gz mag1_bet.nii.gz -R -f 0.6
		# bet $inDir/$subj\_ses-01_run-01_magnitude1.nii.gz mag1_bet.nii.gz -R -f 0.6
		bet $inDir/$subj\_ses-01_run-02_magnitude1.nii.gz mag1_bet.nii.gz -R -f 0.6

    # fsl_prepare_fieldmap SIEMENS $inDir/$subj\_ses-01_phasediff.nii.gz mag1_bet dwi_fieldmap_rads 2.46
		# fsl_prepare_fieldmap SIEMENS $inDir/$subj\_ses-01_run-01_phasediff.nii.gz mag1_bet dwi_fieldmap_rads 2.46
	  fsl_prepare_fieldmap SIEMENS $inDir/$subj\_ses-01_run-02_phasediff.nii.gz mag1_bet dwi_fieldmap_rads 2.46

    # fslmaths dwi_fieldmap_rads -div 6.28 dwi_fieldmap_Hz
		fslmaths dwi_fieldmap_rads -div 6.28 dwi_fieldmap_Hz_run-02

    # mv dwi_fieldmap_Hz.nii.gz /projects/nforde/POND/fmap/$subj/
	  mv dwi_fieldmap_Hz_run-02.nii.gz /projects/nforde/POND/fmap/$subj/

		cd /projects/nforde/POND/fmap/$subj/

    # if [[ -f "dwi_fieldmap_Hz.nii.gz" ]]; then
		if [ -f "dwi_fieldmap_Hz.nii.gz" ] || [ -f "dwi_fieldmap_Hz_run-02.nii.gz" ]; then
      rm -r tmp
    fi
  fi
done
