#!/usr/bin/env bash -l

module load MRtrix3/3.0_RC2
module load FSL/5.0.10
module load connectome-workbench/1.2.3
#--------------------------------------------------------------------------------
## mrtrix3 tractography

subj=$1
echo $subj

tmpdir=$(mktemp --tmpdir=/export/ramdisk -d tmp${subj}.XXXXXX)

function cleanup_ramdisk {
    echo -n "Cleaning up ramdisk directory ${tmpdir} on "
    date
    rm -rf ${tmpdir}
    echo -n "done at "
    date
}

#trap the termination signal, and call the function 'trap_term' when
# that happens, so results may be saved.
trap cleanup_ramdisk EXIT SIGTERM


########### ------------ GET REQUIRED FILES ---------- ###############
cd $tmpdir

indir=/KIMEL/tigrlab/projects/nforde/POND/dtifit/$subj
indir2=/KIMEL/tigrlab/projects/mjoseph/studies/pond/pipelines/fmriprep/pond_out/ciftify/$subj
indir3=/KIMEL/tigrlab/projects/nforde/atlases
outdir=/KIMEL/tigrlab/projects/nforde/POND/CSD/$subj

# cp input file
#subject specific
cp $indir/data.nii.gz $tmpdir/dMRI.nii.gz
cp $indir/nodif_brain.nii.gz $tmpdir/nodif_brain.nii.gz
cp $indir/nodif_brain_mask.nii.gz $tmpdir/nodif_brain_mask.nii.gz
cp $indir2/T1w/T1w_brain.nii.gz $tmpdir/T1.nii.gz
cp $indir/dwi.bval $tmpdir/bvals
cp $indir/data.eddy_rotated_bvecs $tmpdir/bvecs

cp $indir2/T1w/fsaverage_LR32k/$subj.L.pial.32k_fs_LR.surf.gii $tmpdir/Lpial.surf.gii
cp $indir2/T1w/fsaverage_LR32k/$subj.L.white.32k_fs_LR.surf.gii $tmpdir/Lwhite.surf.gii
cp $indir2/T1w/fsaverage_LR32k/$subj.L.midthickness.32k_fs_LR.surf.gii $tmpdir/Lmid.surf.gii
cp $indir2/T1w/fsaverage_LR32k/$subj.R.pial.32k_fs_LR.surf.gii $tmpdir/Rpial.surf.gii
cp $indir2/T1w/fsaverage_LR32k/$subj.R.white.32k_fs_LR.surf.gii $tmpdir/Rwhite.surf.gii
cp $indir2/T1w/fsaverage_LR32k/$subj.R.midthickness.32k_fs_LR.surf.gii $tmpdir/Rmid.surf.gii

cp $indir2/T1w/aparc.a2009s+aseg.nii.gz $tmpdir/aparcaseg.nii.gz

#atlas stuff
cp $indir3/glasserL.label.gii $tmpdir/
cp $indir3/glasserR.label.gii $tmpdir/

cp $indir3/ColeAnticevicNetPartition/CortexL.label.gii $tmpdir/
cp $indir3/ColeAnticevicNetPartition/CortexR.label.gii $tmpdir/
cp $indir3/ColeAnticevicNetPartition/ColeAnticevic_wSubcorGSR_parcels_LR.nii $tmpdir/Cole_subcort.nii
cp $indir2/MNINonLinear/xfms/T1w2StandardLinear.mat $tmpdir/
cp $indir2/MNINonLinear/xfms/Standard2T1w_warp_noaffine.nii.gz $tmpdir/

#--------------------------------------------------------------------------------
########### ------------ MRtrix Tractography ---------- ###############

#anatomically constrained tractography (ACT) use 5ttgen script ## Not using ACT (doesn't let tracts intersect with GM ROIs properly) Still generating the gmwmi to seed from
#register T1 to diffusion space first
flirt -dof 6 -in T1.nii.gz -ref nodif_brain.nii.gz -omat xformT1_to_diff.mat -out T1_diff
5ttgen fsl -nocrop -premasked T1_diff.nii.gz 5TT.nii.gz
5tt2gmwmi 5TT.nii.gz gmwmi.nii.gz #-force
fslmaths gmwmi.nii.gz -bin gmwmi_bin.nii.gz

# generate response function
dwi2response tournier dMRI.nii.gz -fslgrad bvecs bvals response.txt
#shview response.txt

# generate FODs
dwi2fod csd dMRI.nii.gz response.txt FOD.nii.gz -mask nodif_brain_mask.nii.gz -fslgrad bvecs bvals
#mrview $dMRI -odf.load_sh FOD.nii.gz

# tractography deterministic
#tckgen -algorithm SD_STREAM FOD.nii.gz det.tck -rk4 -act 5TT.nii.gz -seed_gmwmi gmwmi_bin.nii.gz -select 5000000
# probabilistic
tckgen FOD.nii.gz prob.tck -seed_image gmwmi_bin.nii.gz -select 5000000 ## seeding from a binarised gmwmi
#mrview $dMRI -tractography.load det.tck

#use sift to filter tracks based on spherical harmonics
# tcksift2 det.tck FOD.nii.gz -act 5TT.nii.gz det_weights.txt
tcksift2 prob.tck FOD.nii.gz prob_weights.txt

#--------------------------------------------------------------------------------
########### ------------ Individualised Atlases ---------- ###############

## making individual GLASSER atlases
wb_command -label-to-volume-mapping glasserL.label.gii Lmid.surf.gii T1.nii.gz Lrois.nii.gz -ribbon-constrained Lwhite.surf.gii Lpial.surf.gii
wb_command -label-to-volume-mapping glasserR.label.gii Rmid.surf.gii T1.nii.gz Rrois.nii.gz -ribbon-constrained Rwhite.surf.gii Rpial.surf.gii
#add 180 to left hemi labels to differentiate from right
fslmaths Lrois.nii.gz -add 180 -thr 181 Lrois_plus180.nii.gz

#merge left and right and do some trickery to remove any overlapping voxels
fslmaths Lrois.nii.gz -bin Lbin.nii.gz
fslmaths Rrois.nii.gz -bin Rbin.nii.gz
fslmaths Rbin.nii.gz -add Lbin.nii.gz -thr 2 -binv overlapCort.nii.gz
fslmaths Lrois_plus180.nii.gz -add Rrois.nii.gz -mul overlapCort.nii.gz glasserT1.nii.gz

flirt -in glasserT1.nii.gz -ref nodif_brain.nii.gz -interp nearestneighbour -applyxfm -init xformT1_to_diff.mat -out glasser.nii.gz
fslmaths glasser.nii.gz -bin glasserbin.nii.gz

## getting individual COLE-ANTICEVIC parcellation (including cortex and subcortical)
## get cortex
wb_command -label-to-volume-mapping CortexL.label.gii Lmid.surf.gii T1.nii.gz Lrois_cole.nii.gz -ribbon-constrained Lwhite.surf.gii Lpial.surf.gii
wb_command -label-to-volume-mapping CortexR.label.gii Rmid.surf.gii T1.nii.gz Rrois_cole.nii.gz -ribbon-constrained Rwhite.surf.gii Rpial.surf.gii
#merge left and right and do some trickery to remove any overlapping voxels
fslmaths Lrois_cole.nii.gz -bin Lbin_cole.nii.gz
fslmaths Rrois_cole.nii.gz -bin Rbin_cole.nii.gz
fslmaths Rbin_cole.nii.gz -add Lbin_cole.nii.gz -thr 2 -binv overlapCort_cole.nii.gz
fslmaths Lrois_cole.nii.gz -add Rrois_cole.nii.gz -mul overlapCort_cole.nii.gz ColeCortT1.nii.gz

flirt -in ColeCortT1.nii.gz -ref nodif_brain.nii.gz -interp nearestneighbour -applyxfm -init xformT1_to_diff.mat -out ColeCort.nii.gz
fslmaths ColeCort.nii.gz -bin ColeCort_bin.nii.gz

## get subcortical
convert_xfm -omat Standard2T1wLinear.mat -inverse T1w2StandardLinear.mat
convert_xfm -omat Standard2diff.mat -concat xformT1_to_diff.mat Standard2T1wLinear.mat
## apply warp field and linear transform to get subcortical parcellation to diffusion space
wb_command -volume-warpfield-resample Cole_subcort.nii Standard2T1w_warp_noaffine.nii.gz Cole_subcort.nii ENCLOSING_VOXEL subcortunwarp.nii
flirt -in subcortunwarp.nii -ref T1_diff.nii.gz -interp nearestneighbour -applyxfm -init Standard2diff.mat -out Cole_subcort_diff.nii.gz

## merge to get Cortex and subcortex
fslmaths Cole_subcort_diff.nii.gz -bin -add glasserbin.nii.gz -thr 2 -binv Cole_cortex_subcortex_overlap.nii.gz
fslmaths Cole_subcort_diff.nii.gz -mul Cole_cortex_subcortex_overlap.nii.gz -add ColeCort.nii.gz ColeAnti.nii.gz

## making individual DESIKAN-KILLIANY atlases
flirt -in aparcaseg.nii.gz -ref nodif_brain.nii.gz -interp nearestneighbour -applyxfm -init xformT1_to_diff.mat -out DK.nii.gz

## getting individual aseg subcortical parcellation from Aseg to merge with glasser
# "8" "10" "11" "12" "13" "17" "18" "26" "27" "28" "47" "49" "50" "51" "52" "53" "54" "58" "59" "60"; do
# fslmaths aparcaseg.nii.gz -thr 7.5 -uthr 8.5 -bin aseg8.nii.gz
# fslmaths aparcaseg.nii.gz -thr 9.5 -uthr 10.5 -bin -mul 2 aseg10.nii.gz
# fslmaths aparcaseg.nii.gz -thr 10.5 -uthr 11.5 -bin -mul 3 aseg11.nii.gz
# fslmaths aparcaseg.nii.gz -thr 11.5 -uthr 12.5 -bin -mul 4 aseg12.nii.gz
# fslmaths aparcaseg.nii.gz -thr 12.5 -uthr 13.5 -bin -mul 5 aseg13.nii.gz
# fslmaths aparcaseg.nii.gz -thr 16.5 -uthr 17.5 -bin -mul 6 aseg17.nii.gz
# fslmaths aparcaseg.nii.gz -thr 17.5 -uthr 18.5 -bin -mul 7 aseg18.nii.gz
# fslmaths aparcaseg.nii.gz -thr 25.5 -uthr 26.5 -bin -mul 8 aseg26.nii.gz
# fslmaths aparcaseg.nii.gz -thr 26.5 -uthr 27.5 -bin -mul 9 aseg27.nii.gz
# fslmaths aparcaseg.nii.gz -thr 27.5 -uthr 28.5 -bin -mul 10 aseg28.nii.gz
# fslmaths aparcaseg.nii.gz -thr 46.5 -uthr 47.5 -bin -mul 11 aseg47.nii.gz
# fslmaths aparcaseg.nii.gz -thr 48.5 -uthr 49.5 -bin -mul 12 aseg49.nii.gz
# fslmaths aparcaseg.nii.gz -thr 49.5 -uthr 50.5 -bin -mul 13 aseg50.nii.gz
# fslmaths aparcaseg.nii.gz -thr 50.5 -uthr 51.5 -bin -mul 14 aseg51.nii.gzflirt -in aparcaseg.nii.gz -ref nodif_brain.nii.gz -interp nearestneighbour -applyxfm -init xformT1_to_diff.mat -out DK.nii.gz

# fslmaths aparcaseg.nii.gz -thr 51.5 -uthr 52.5 -bin -mul 15 aseg52.nii.gz
# fslmaths aparcaseg.nii.gz -thr 52.5 -uthr 53.5 -bin -mul 16 aseg53.nii.gz
# fslmaths aparcaseg.nii.gz -thr 53.5 -uthr 54.5 -bin -mul 17 aseg54.nii.gz
# fslmaths aparcaseg.nii.gz -thr 57.5 -uthr 58.5 -bin -mul 18 aseg58.nii.gz
# fslmaths aparcaseg.nii.gz -thr 58.5 -uthr 59.5 -bin -mul 19 aseg59.nii.gz
# fslmaths aparcaseg.nii.gz -thr 59.5 -uthr 60.5 -bin -mul 20 aseg60.nii.gz
#
# #merge aseg regions and add 360 so there's no overlap in integers from glasser
# fslmaths aseg8.nii.gz -add aseg10.nii.gz -add aseg11.nii.gz -add aseg12.nii.gz -add aseg13.nii.gz -add aseg17.nii.gz -add aseg18.nii.gz \
#   -add aseg26.nii.gz -add aseg27.nii.gz -add aseg28.nii.gz -add aseg47.nii.gz -add aseg49.nii.gz -add aseg50.nii.gz -add aseg51.nii.gz \
#    -add aseg52.nii.gz -add aseg53.nii.gz -add aseg54.nii.gz -add aseg58.nii.gz -add aseg59.nii.gz -add aseg60.nii.gz \
#    -add 360 -thr 360.5 asegT1.nii.gz
#
# flirt -in asegT1.nii.gz -ref nodif_brain.nii.gz -interp nearestneighbour -applyxfm -init xformT1_to_diff.mat -out aseg.nii.gz
#
# fslmaths aseg.nii.gz -bin -add glasserbin.nii.gz -thr 2 -binv -mul aseg.nii.gz asegNoOverlap.nii.gz
# fslmaths asegNoOverlap.nii.gz -add glasser.nii.gz glasser_aseg.nii.gz

#--------------------------------------------------------------------------------
########### ------------ EXTRACT MATRICES ---------- ###############
## generate connectome
# make connectome (weighted by number of stremlines normalised by streamline length)
# tck2connectome det.tck glasser_aseg.nii.gz det_glasser_aseg.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in det_weights.txt
# tck2connectome det.tck glasser_aseg.nii.gz det_length_glasser_aseg.csv -scale_length -stat_edge mean
# tck2connectome det.tck glasser_cole.nii.gz det_glasser_cole.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in det_weights.txt
# tck2connectome det.tck glasser_cole.nii.gz det_length_glasser_cole.csv -scale_length -stat_edge mean
# tck2connectome det.tck DK.nii.gz det_DK.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in det_weights.txt
# tck2connectome det.tck DK.nii.gz det_length_DK.csv -scale_length -stat_edge mean
#prob
tck2connectome prob.tck glasser.nii.gz prob_glasser.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in prob_weights.txt
tck2connectome prob.tck glasser.nii.gz prob_length_glasser.csv -scale_length -stat_edge mean
# tck2connectome prob.tck glasser_aseg.nii.gz prob_glasser_aseg.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in prob_weights.txt
# tck2connectome prob.tck glasser_aseg.nii.gz prob_length_glasser_aseg.csv -scale_length -stat_edge mean
tck2connectome prob.tck ColeAnti.nii.gz prob_ColeAnti.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in prob_weights.txt
tck2connectome prob.tck ColeAnti.nii.gz prob_length_ColeAnti.csv -scale_length -stat_edge mean
tck2connectome prob.tck DK.nii.gz prob_DK.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in prob_weights.txt
tck2connectome prob.tck DK.nii.gz prob_length_DK.csv -scale_length -stat_edge mean
##-------------------------------------------------------------------------------
## extract voxel count of the gmwmi within each ROI	(will normalise the connectome by this in R)

fslstats -K glasser.nii.gz gmwmi_bin.nii.gz -V > voxel_count_glasser.txt
# fslstats -K glasser_aseg.nii.gz gmwmi_bin.nii.gz -V > voxel_count_glasser_aseg.txt
fslstats -K ColeAnti.nii.gz gmwmi_bin.nii.gz -V > voxel_count_ColeAnti.txt
fslstats -K DK.nii.gz gmwmi_bin.nii.gz -V > voxel_count_DK.txt
##copy required files
cp *.csv *.txt FOD.nii.gz 5TT.nii.gz gmwmi.nii.gz glasser.nii.gz ColeAnti.nii.gz DK.nii.gz $outdir/
