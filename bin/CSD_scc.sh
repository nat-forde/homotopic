
#!/usr/bin/

module load MRtrix3/3.0_RC2
module load FSL/5.0.9
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
trap cleanup_ramdisk EXIT

cd $tmpdir
# cp input file
cp /KIMEL/tigrlab/archive/data-2.0/OBI_POND/data/$subj/*_ec.nii $tmpdir/dMRI.nii
cp /KIMEL/tigrlab/archive/data-2.0/OBI_POND/data/$subj/${subj}_mask.nii $tmpdir/brain_mask.nii
cp /KIMEL/tigrlab/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/T1w_brain.nii.gz $tmpdir/T1.nii.gz
cp /KIMEL/tigrlab/archive/data-2.0/OBI_POND/data/$subj/*.bval $tmpdir/bval.bval
cp /KIMEL/tigrlab/archive/data-2.0/OBI_POND/data/$subj/*.bvec $tmpdir/bvec.bvec

cp /KIMEL/tigrlab/scratch/nforde/homotopic/atlases/glasserL.label.gii $tmpdir
cp /KIMEL/tigrlab/scratch/nforde/homotopic/atlases/glasserR.label.gii $tmpdir
cp /KIMEL/tigrlab/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/fsaverage_LR32k/$subj.L.pial.32k_fs_LR.surf.gii $tmpdir/Lpial.surf.gii
cp /KIMEL/tigrlab/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/fsaverage_LR32k/$subj.L.white.32k_fs_LR.surf.gii $tmpdir/Lwhite.surf.gii
cp /KIMEL/tigrlab/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/fsaverage_LR32k/$subj.L.midthickness.32k_fs_LR.surf.gii $tmpdir/Lmid.surf.gii
cp /KIMEL/tigrlab/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/fsaverage_LR32k/$subj.R.pial.32k_fs_LR.surf.gii $tmpdir/Rpial.surf.gii
cp /KIMEL/tigrlab/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/fsaverage_LR32k/$subj.R.white.32k_fs_LR.surf.gii $tmpdir/Rwhite.surf.gii
cp /KIMEL/tigrlab/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/fsaverage_LR32k/$subj.R.midthickness.32k_fs_LR.surf.gii $tmpdir/Rmid.surf.gii
#--------------------------------------------------------------------------------
## mrtrix3 CSD and tractography

# generate response function
if [[ ! -f "/KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/det_connectome.csv" ]]; then
	#anatomically constrained tractography (ACT) use 5ttgen script
	#register T1 to diffusion space first
	fslroi dMRI.nii b0 0 1
	flirt -dof 6 -in T1.nii.gz -ref b0.nii.gz -omat xformT1_to_diff.mat -out T1_diff
	5ttgen fsl -nocrop -premasked T1_diff.nii.gz 5TT.nii.gz  #-t2 <T2 image optional>
	5tt2gmwmi 5TT.nii.gz gmwmi.nii.gz #-force

	dwi2response tournier dMRI.nii -fslgrad bvec.bvec bval.bval response.txt #-force # to overwrite
#shview response.txt

# generate FODs
	dwi2fod csd dMRI.nii response.txt FOD.nii.gz -mask brain_mask.nii -fslgrad bvec.bvec bval.bval #-force # to overwrite
#mrview $dMRI -odf.load_sh FOD.nii.gz

# tractography deterministic
	#generate tracks 100million should be doable on the cluster # Check computing required and storage space
	sh2peaks FOD.nii.gz peaks.nii.gz
	tckgen -algorithm FACT peaks.nii.gz det.tck -act 5TT.nii.gz -seed_gmwmi gmwmi.nii.gz -step 0.5 -angle 30 -minlength 10 -select 100000000
#mrview $dMRI -tractography.load det.tck

#use sift to filter tracks based on spherical harmonics
	tcksift2 det.tck FOD.nii.gz -act 5TT.nii.gz det_weights.txt
	#tcksift2 prob.tck FOD.nii.gz -act 5TT.nii.gz prob_weights.txt

#--------------------------------------------------------------------------------
## making individual glasser atlases
	wb_command -label-to-volume-mapping glasserL.label.gii Lmid.surf.gii T1_diff.nii.gz Lrois.nii.gz -ribbon-constrained Lwhite.surf.gii Lpial.surf.gii
	wb_command -label-to-volume-mapping glasserR.label.gii Rmid.surf.gii T1_diff.nii.gz Rrois.nii.gz -ribbon-constrained Rwhite.surf.gii Rpial.surf.gii
	#add 180 to left hemi labels to differentiate from right
	fslmaths Lrois.nii.gz -add 180 -thr 181 Lrois_plus180.nii.gz
	#merge left and right and do some trickery to remove any overlapping voxels
	fslmaths Lrois_plus180.nii.gz -add Rrois.nii.gz ROIs.nii.gz
	fslmaths Lrois.nii.gz -bin Lbin.nii.gz
	fslmaths Rrois.nii.gz -bin Rbin.nii.gz
	fslmaths Rbin.nii.gz -add Lbin.nii.gz Cbin.nii.gz
	fslmaths Cbin.nii.gz -thr 2 -binv overlap.nii.gz
	fslmaths overlap.nii.gz -mul ROIs.nii.gz glasser.nii.gz

#--------------------------------------------------------------------------------
## generate connectome
	# make connectome (weighted by number of stremlines normalised by streamline length)
	tck2connectome det.tck glasser.nii.gz det_connectome.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in det_weights.txt
	tck2connectome det.tck glasser.nii.gz det_length_connectome.csv -scale_length -stat_edge mean

##-------------------------------------------------------------------------------
## extract voxel count of the gmwmi within each ROI	(will normalis the connectome by this in R)
	fslmaths gmwmi.nii.gz -bin gmwmi_bin.nii.gz
	fslstats -K glasser.nii.gz gmwmi_bin.nii.gz -V > voxel_count.txt

##copy required files
	cp det_connectome.csv /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/
	cp det_length_connectome.csv /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/
	cp response.txt /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/
	cp FOD.nii.gz /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/
	cp 5TT.nii.gz /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/
	cp gmwmi.nii.gz /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/
	cp glasser.nii.gz /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/
	cp voxel_count.txt /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/
fi
