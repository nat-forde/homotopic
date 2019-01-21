
#!/usr/bin/bash -l

module load MRtrix3/3.0_RC2
module load FSL/5.0.10
module load connectome-workbench/1.2.3

#--------------------------------------------------------------------------------
## mrtrix3 tractography

subj=$1
echo $subj

tmpdir=$(mktemp --tmpdir=/export/ramdisk -d tmp.XXXXXX)

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

cd $tmpdir
# cp input file
indir=/KIMEL/tigrlab/projects/nforde/POND/dtifit/$subj
indir2=/KIMEL/tigrlab/projects/mjoseph/studies/pond/pipelines/fmriprep/pond_out/ciftify/$subj
indir3=/KIMEL/tigrlab/projects/nforde/atlases/ColeAnticevicNetPartition
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
cp /KIMEL/tigrlab/projects/nforde/atlases/glasserL.label.gii $tmpdir/
cp /KIMEL/tigrlab/projects/nforde/atlases/glasserR.label.gii $tmpdir/

cp $indir3/SeparateHemispheres/subcortex_atlas_GSR_parcels_L.nii $tmpdir/
cp $indir3/SeparateHemispheres/subcortex_atlas_GSR_parcels_R.nii $tmpdir/
cp $indir2/MNINonLinear/xfms/T1w2StandardLinear.mat $tmpdir/
cp $indir2/MNINonLinear/xfms/Standard2T1w_warp_noaffine.nii.gz $tmpdir/
#--------------------------------------------------------------------------------
## mrtrix3 CSD and tractography

# generate response function
if [[ ! -f "/KIMEL/tigrlab/projects/nforde/POND/CSD/$subj/prob_connectome.csv" ]]; then
	#anatomically constrained tractography (ACT) use 5ttgen script
	#register T1 to diffusion space first
	#fslroi dMRI.nii.gz b0 0 1
  #bet b0 nodif_brain -m -R -f 0.5
	flirt -dof 6 -in T1.nii.gz -ref nodif_brain.nii.gz -omat xformT1_to_diff.mat -out T1_diff
	5ttgen fsl -nocrop -premasked T1_diff.nii.gz 5TT.nii.gz  #-t2 <T2 image optional>
	5tt2gmwmi 5TT.nii.gz gmwmi.nii.gz #-force

  # printf "1000 1600 2600" > shells.txt not sure if this is necessary, if so then -shell shells.txt should be added below

	dwi2response dhollander dMRI.nii.gz wm_response.txt gm_response.txt csf_response.txt -fslgrad bvecs bvals #-force # to overwrite
#shview response.txt

# generate FODs
  dwi2fod msmt_csd dMRI.nii.gz wm_response.txt FOD.nii.gz gm_response.txt gm.nii.gz csf_response.txt csf.nii.gz -mask nodif_brain_mask.nii.gz -fslgrad bvecs bvals
#mrview $dMRI -odf.load_sh FOD.nii.gz

# tractography probabilistic
  # tckgen FOD.nii.gz prob.tck -act 5TT.nii.gz -seed_gmwmi gmwmi.nii.gz -select 5000000
#mrview $dMRI -tractography.load det.tck
  sh2peaks FOD.nii.gz peaks.nii.gz
  tckgen -algorithm FACT peaks.nii.gz det.tck -act 5TT.nii.gz -seed_gmwmi gmwmi.nii.gz -select 5000000

#--------------------------------------------------------------------------------
#use sift to filter tracks based on spherical harmonics
	tcksift2 det.tck FOD.nii.gz -act 5TT.nii.gz det_weights.txt
	# tcksift2 prob.tck FOD.nii.gz -act 5TT.nii.gz prob_weights.txt

#--------------------------------------------------------------------------------
## making individual glasser atlases
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

## getting individual ColeAnticevic subcortical parcellation
  convert_xfm -omat Standard2T1wLinear.mat -inverse T1w2StandardLinear.mat
  convert_xfm -omat Standard2diff.mat -concat xformT1_to_diff.mat Standard2T1wLinear.mat
## apply warp field and linear transform to get subcortical parcellation to diffusion space
  wb_command -volume-warpfield-resample subcortex_atlas_GSR_parcels_L.nii Standard2T1w_warp_noaffine.nii.gz subcortex_atlas_GSR_parcels_L.nii ENCLOSING_VOXEL subcortwarpL.nii
  flirt -in subcortwarpL.nii -ref T1_diff.nii.gz -interp nearestneighbour -applyxfm -init Standard2diff.mat -out subcortL.nii.gz
  wb_command -volume-warpfield-resample subcortex_atlas_GSR_parcels_R.nii Standard2T1w_warp_noaffine.nii.gz subcortex_atlas_GSR_parcels_R.nii ENCLOSING_VOXEL subcortwarpR.nii
  flirt -in subcortwarpR.nii -ref T1_diff.nii.gz -interp nearestneighbour -applyxfm -init Standard2diff.mat -out subcortR.nii.gz

  fslmaths subcortL.nii.gz -bin subcortL_bin.nii.gz
  fslmaths subcortR.nii.gz -bin subcortR_bin.nii.gz
  fslmaths subcortL_bin.nii.gz -add subcortR_bin.nii.gz -thr 2 -binv overlapSubCort.nii.gz
  fslmaths subcortL.nii.gz -add subcortR.nii.gz -mul overlapSubCort.nii.gz -add 1000 -thr 1001 Cole.nii.gz

	fslmaths Cole.nii.gz -bin -add glasserbin.nii.gz -thr 2 -binv GC_overlap.nii.gz
	fslmaths Cole.nii.gz -mul GC_overlap.nii.gz -add glasser.nii.gz glasser_cole.nii.gz

## getting individual aseg subcortical parcellation from FS
  # "8" "10" "11" "12" "13" "17" "18" "26" "27" "28" "47" "49" "50" "51" "52" "53" "54" "58" "59" "60"; do
  fslmaths aparcaseg.nii.gz -thr 7.5 -uthr 8.5 -bin aseg8.nii.gz
  fslmaths aparcaseg.nii.gz -thr 9.5 -uthr 10.5 -bin -mul 2 aseg10.nii.gz
  fslmaths aparcaseg.nii.gz -thr 10.5 -uthr 11.5 -bin -mul 3 aseg11.nii.gz
  fslmaths aparcaseg.nii.gz -thr 11.5 -uthr 12.5 -bin -mul 4 aseg12.nii.gz
  fslmaths aparcaseg.nii.gz -thr 12.5 -uthr 13.5 -bin -mul 5 aseg13.nii.gz
  fslmaths aparcaseg.nii.gz -thr 16.5 -uthr 17.5 -bin -mul 6 aseg17.nii.gz
  fslmaths aparcaseg.nii.gz -thr 17.5 -uthr 18.5 -bin -mul 7 aseg18.nii.gz
  fslmaths aparcaseg.nii.gz -thr 25.5 -uthr 26.5 -bin -mul 8 aseg26.nii.gz
  fslmaths aparcaseg.nii.gz -thr 26.5 -uthr 27.5 -bin -mul 9 aseg27.nii.gz
  fslmaths aparcaseg.nii.gz -thr 27.5 -uthr 28.5 -bin -mul 10 aseg28.nii.gz
  fslmaths aparcaseg.nii.gz -thr 46.5 -uthr 47.5 -bin -mul 11 aseg47.nii.gz
  fslmaths aparcaseg.nii.gz -thr 48.5 -uthr 49.5 -bin -mul 12 aseg49.nii.gz
  fslmaths aparcaseg.nii.gz -thr 49.5 -uthr 50.5 -bin -mul 13 aseg50.nii.gz
  fslmaths aparcaseg.nii.gz -thr 50.5 -uthr 51.5 -bin -mul 14 aseg51.nii.gz
  fslmaths aparcaseg.nii.gz -thr 51.5 -uthr 52.5 -bin -mul 15 aseg52.nii.gz
  fslmaths aparcaseg.nii.gz -thr 52.5 -uthr 53.5 -bin -mul 16 aseg53.nii.gz
  fslmaths aparcaseg.nii.gz -thr 53.5 -uthr 54.5 -bin -mul 17 aseg54.nii.gz
  fslmaths aparcaseg.nii.gz -thr 57.5 -uthr 58.5 -bin -mul 18 aseg58.nii.gz
  fslmaths aparcaseg.nii.gz -thr 58.5 -uthr 59.5 -bin -mul 19 aseg59.nii.gz
  fslmaths aparcaseg.nii.gz -thr 59.5 -uthr 60.5 -bin -mul 20 aseg60.nii.gz

  fslmaths aseg8.nii.gz -add aseg10.nii.gz -add aseg11.nii.gz -add aseg12.nii.gz -add aseg13.nii.gz -add aseg17.nii.gz -add aseg18.nii.gz \
    -add aseg26.nii.gz -add aseg27.nii.gz -add aseg28.nii.gz -add aseg47.nii.gz -add aseg49.nii.gz -add aseg50.nii.gz -add aseg51.nii.gz \
     -add aseg52.nii.gz -add aseg53.nii.gz -add aseg54.nii.gz -add aseg58.nii.gz -add aseg59.nii.gz -add aseg60.nii.gz \
     -add 360 -thr 360.5 asegT1.nii.gz

  flirt -in asegT1.nii.gz -ref nodif_brain.nii.gz -interp nearestneighbour -applyxfm -init xformT1_to_diff.mat -out aseg.nii.gz
  flirt -in aparcaseg.nii.gz -ref nodif_brain.nii.gz -interp nearestneighbour -applyxfm -init xformT1_to_diff.mat -out DK.nii.gz

	fslmaths aseg.nii.gz -bin -add glasserbin.nii.gz -thr 2 -binv -mul aseg.nii.gz asegNoOverlap.nii.gz
  fslmaths asegNoOverlap.nii.gz -add glasser.nii.gz glasser_aseg.nii.gz
#--------------------------------------------------------------------------------
## generate connectome
	# make connectome (weighted by number of stremlines normalised by streamline length)
	# tck2connectome prob.tck glasser_aseg.nii.gz prob_connectome.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in prob_weights.txt
	# tck2connectome prob.tck glasser_aseg.nii.gz prob_length_connectome.csv -scale_length -stat_edge mean
  tck2connectome det.tck glasser_aseg.nii.gz det_glasser_aseg.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in det_weights.txt
	tck2connectome det.tck glasser_aseg.nii.gz det_length_glasser_aseg.csv -scale_length -stat_edge mean
  tck2connectome det.tck glasser_cole.nii.gz det_glasser_cole.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in det_weights.txt
  tck2connectome det.tck glasser_cole.nii.gz det_length_glasser_cole.csv -scale_length -stat_edge mean
  tck2connectome det.tck DK.nii.gz det_DK.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in det_weights.txt
  tck2connectome det.tck DK.nii.gz det_length_DK.csv -scale_length -stat_edge mean
#--------------------------------------------------------------------------------
## generate connectome
	# make connectome (weighted by number of stremlines normalised by streamline length)
	# tck2connectome prob.tck glasser.nii.gz prob_connectome.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in prob_weights.txt
	# tck2connectome prob.tck glasser.nii.gz prob_length_connectome.csv -scale_length -stat_edge mean

##-------------------------------------------------------------------------------
## extract voxel count of the gmwmi within each ROI	(will normalise the connectome by this in R)
  fslmaths gmwmi.nii.gz -bin gmwmi_bin.nii.gz
  fslstats -K glasser_aseg.nii.gz gmwmi_bin.nii.gz -V > voxel_count_glasser_aseg.txt
  fslstats -K glasser_cole.nii.gz gmwmi_bin.nii.gz -V > voxel_count_glasser_cole.txt
  fslstats -K DK.nii.gz gmwmi_bin.nii.gz -V > voxel_count_DK.txt
##copy required files
  cp *.csv *.txt FOD.nii.gz 5TT.nii.gz gmwmi.nii.gz glasser_*.nii.gz $outdir/

fi
