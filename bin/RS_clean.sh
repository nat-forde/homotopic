#!/bin/bash env bash

# This is adapted from Erins's SZ PINT work. It should clean RS data as a post-processing ciftify step with singularity

# The functions is:
# ciftify_clean_img - to denoise and smooth the scans

# the inputs are:
#   subject -> the surbect id example: "sub-02"
#   func_base -> the bids bold base string example: "task-rhymejudgment_bold"
#   outdir -> the base directory for all the derivaties example: $SCRATCH/bids_outputs/${dataset}/fmriprep_p05
#   sing_home -> a ramdom empty folder to bind singularity's /home to example: sing_home=$SCRATCH/sing_home/ciftify/$dataset
#   ciftify_container -> full path to the singularty container with the ciftify env inside

subject=$1
#session=$2 #na
func_base=$2 #ses-01_task-rest (with run number if applicable)
archive_pipedir=$3  #/projects/mjoseph/studies/pond/pipelines/fmriprep/pond_out
outdir=$4 #/projects/nforde/POND/rsMRI
sing_home=$5 #/projects/nforde/POND/rsMRI/sing
ciftify_container=$6 #
run=$7
# module load singularity
# module load gnu-parallel/20180322

# bash RS_clean.sh sub-0880002 ses-01_task-rest_bold_Atlas_s0 \
# /KIMEL/tigrlab/projects/mjoseph/studies/pond/pipelines/fmriprep/pond_out \
# /KIMEL/tigrlab/projects/nforde/POND/rsMRI \
# /KIMEL/tigrlab/projects/nforde/POND/rsMRI/sing \
# /KIMEL/tigrlab/archive/code/containers/FMRIPREP_CIFTIFY/tigrlab_fmriprep_ciftify_1.1.2-2.1.0-2018-10-12-dcfba6cc0add.img

##

export ciftify_container

#mkdir -p ${outdir}/ciftify_clean_img/${subject}

# Step 1. Run the cleaning and smoothing script
# note: before calling this script, you need to place a clean_config file into ${outdir}/ciftify_clean_img
#       sample clean_config.json files can be found in https://github.com/edickie/ciftify/tree/master/ciftify/data/cleaning_configs
#    example: cp ~/code/ciftify/ciftify/data/cleaning_configs/24MP_8Phys_4GSR.json ${outdir}/ciftify_clean_img
# In this case I manually edited to be:
# {
#   "--detrend": true,
#   "--standardize": true,
#   "--cf-cols": "X,Y,Z,RotX,RotY,RotZ,CSF,WhiteMatter,GlobalSignal",
#   "--cf-sq-cols": "X,Y,Z,RotX,RotY,RotZ,CSF,WhiteMatter,GlobalSignal",
#   "--cf-td-cols": "X,Y,Z,RotX,RotY,RotZ,CSF,WhiteMatter,GlobalSignal",
#   "--cf-sqtd-cols": "X,Y,Z,RotX,RotY,RotZ,CSF,WhiteMatter,GlobalSignal",
#   "--low-pass": 0.1,
#   "--high-pass": 0.01,
#   "--drop-dummy-TRs": 3,
#   "--smooth-fwhm": 8

# singularity exec \
    # mkdir -p ${outdir}/${subject}
singularity exec \
  -H ${sing_home} \
  -B ${outdir}:/output \
  -B ${archive_pipedir}:/archiveout \
  ${ciftify_container} ciftify_clean_img \
      --output-file=/output/${subject}/${subject}_${func_base}_p36.dtseries.nii \
      --clean-config=/output/36P.json \
      --confounds-tsv=/archiveout/fmriprep/${subject}/ses-01/func/${subject}_${func_base}_bold_confounds.tsv \
      --left-surface=/archiveout/ciftify/${subject}/MNINonLinear/fsaverage_LR32k/${subject}.L.midthickness.32k_fs_LR.surf.gii \
      --right-surface=/archiveout/ciftify/${subject}/MNINonLinear/fsaverage_LR32k/${subject}.R.midthickness.32k_fs_LR.surf.gii \
      /archiveout/ciftify/${subject}/MNINonLinear/Results/${func_base}_bold/${func_base}_bold_Atlas_s0.dtseries.nii
