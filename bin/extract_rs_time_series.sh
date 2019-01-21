#!/usr/bin/env bash -l

#get time series for each subj within region
module load python/3.6_ciftify_01
module load connectome-workbench/1.2.3

##---------------------POND-----------------------------------------------------
##------ Glasser atlas -----
cd /projects/nforde/POND/rsMRI
subjects=`ls -d sub-*`
for subj in $subjects; do
	echo $subj
	indir=/projects/nforde/POND/rsMRI/$subj

#mk time series for glasser atlas
  ciftify_meants \
        --outputcsv ${indir}/glasser_meants.csv \
        --outputlabels ${indir}/glasser_roiids.csv \
        ${indir}/${subj}_ses-01_task-rest_bold_p36.dtseries.nii \
        /projects/nforde/atlases/HCP_Glasser_210_CorticalAreas.32k_fs_LR.dlabel.nii
done

##------ Cole-Anticevic -------

cd /projects/nforde/POND/rsMRI
subjects=`ls -d sub-*`
for subj in $subjects; do
	echo $subj
	indir=/projects/nforde/POND/rsMRI/$subj

#mk time series for ColeAnticevic atlas
  ciftify_meants \
        --outputcsv ${indir}/ColeAnti_meants.csv \
        --outputlabels ${indir}/ColeAnti_roiids.csv \
        ${indir}/${subj}_ses-01_task-rest_bold_p36.dtseries.nii \
        /projects/nforde/atlases/ColeAnticevicNetPartition/CortexSubcortex_ColeAnticevic_NetPartition_wSubcorGSR_parcels_LR.dlabel.nii
done


##------- Aparc-Aseg -----------
cd /projects/nforde/POND/rsMRI
subjects=`ls -d sub-*`
for subj in $subjects; do
	echo $subj
	indir=/projects/nforde/POND/rsMRI/$subj

#mk time series for ColeAnticevic atlas
  ciftify_meants \
        --outputcsv ${indir}/DK_meants.csv \
        --outputlabels ${indir}/DK_roiids.csv \
        ${indir}/${subj}_ses-01_task-rest_bold_p36.dtseries.nii \
        /projects/mjoseph/studies/pond/pipelines/fmriprep/pond_out/ciftify/${subj}/MNINonLinear/aparc.a2009s+aseg.nii.gz
done

##---------------------ABIDE----------------------------------------------------
#calc time series per region
# HCP_DIR=/projects/edickie/analysis/ABIDEI/hcp/NYU
# cd $HCP_DIR
# SUBJECTS=`ls -1d NYU*`
#
# TSOUTDIR=/scratch/nforde/homotopic/ABIDE/hcp/glasser_meants
# #mkdir $TSOUTDIR
#
# for SUBJECT in $SUBJECTS; do
#   echo $SUBJECT
#   ciftify_meants \
#         --outputcsv ${TSOUTDIR}/${SUBJECT}_rest_abide25fix_glasser_meants.csv \
#         --outputlabels ${TSOUTDIR}/${SUBJECT}_rest_abide25fix_glasser_roiids.csv \
#         ${SUBJECT}/MNINonLinear/Results/rest_abide25fix/rest_abide25fix_Atlas_s8.dtseries.nii \
#         /scratch/nforde/homotopic/atlases/HCP_Glasser_210_CorticalAreas.32k_fs_LR.dlabel.nii
#
# done
