
#!/usr/bin/

module load MRtrix3/20180123
module load FSL/5.0.9
module load connectome-workbench/1.2.3

#--------------------------------------------------------------------------------
## mrtrix3 tractography

subj=$1
echo $subj


cd /scratch/nforde/homotopic/POND/CSD

out=/scratch/nforde/homotopic/POND/CSD/$subj
if [[ ! -d "${out}" ]]; then
	mkdir $out
fi
cd ${out}

# input file
dMRI=/archive/data-2.0/OBI_POND/data/$subj/*_ec.nii
brain_mask=/archive/data-2.0/OBI_POND/data/$subj/${subj}_mask.nii
T1=/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/T1w_brain.nii.gz
bval=/archive/data-2.0/OBI_POND/data/$subj/*.bval
bvec=/archive/data-2.0/OBI_POND/data/$subj/*.bvec

Llabels=/scratch/nforde/homotopic/atlases/glasserL.label.gii
Rlabels=/scratch/nforde/homotopic/atlases/glasserR.label.gii
Lpial=/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/fsaverage_LR32k/$subj.L.pial.32k_fs_LR.surf.gii
Lwhite=/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/fsaverage_LR32k/$subj.L.white.32k_fs_LR.surf.gii
Lmid=/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/fsaverage_LR32k/$subj.L.midthickness.32k_fs_LR.surf.gii
Rpial=/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/fsaverage_LR32k/$subj.R.pial.32k_fs_LR.surf.gii
Rwhite=/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/fsaverage_LR32k/$subj.R.white.32k_fs_LR.surf.gii
Rmid=/projects/edickie/analysis/POND_RST/hcp/$subj/T1w/fsaverage_LR32k/$subj.R.midthickness.32k_fs_LR.surf.gii
#--------------------------------------------------------------------------------
## mrtrix3 CSD and tractography

# generate response function
if [[ ! -f "response.txt" ]]; then
	dwi2response tournier $dMRI -fslgrad $bvec $bval response.txt #-force # to overwrite
fi	#shview response.txt

# generate FODs
if [[ ! -f "FOD.nii.gz" ]]; then
	dwi2fod csd $dMRI response.txt FOD.nii.gz -mask $brain_mask -fslgrad $bvec $bval #-force # to overwrite
fi #mrview $dMRI -odf.load_sh FOD.nii.gz

#anatomically constrained tractography (ACT) use 5ttgen script
if [[ ! -f "gmwmi.nii.gz" ]]; then
	#register T1 to diffusion space first
	fslroi $dMRI b0 0 1
	flirt -dof 6 -in $T1 -ref b0.nii.gz -omat xformT1_to_diff.mat -out T1_diff
	5ttgen fsl T1_diff.nii.gz -premasked 5TT.nii.gz -nocrop -force #-t2 <T2 image optional>
	5tt2gmwmi 5TT.nii.gz gmwmi.nii.gz #-force
fi

# tractography both probabilistic and deterministic
if [[ ! -f "det.tck" ]]; then
	#generate tracks 100million should be doable on the cluster # Check computing required and storage space
	sh2peaks FOD.nii.gz peaks.nii.gz
	tckgen -algorithm FACT peaks.nii.gz det.tck -act 5TT.nii.gz -seed_gmwmi gmwmi.nii.gz -step 0.5 -angle 30 -minlength 10 -select 50000000
fi
#if [[ ! -f "prob.tck" ]]; then
#	tckgen FOD.nii.gz prob.tck -act 5TT.nii.gz -seed_gmwmi gmwmi.nii.gz -step 0.5 -angle 30 -minlength 20 -select 100000000 #probabilistic is default
#fi
#mrview $dMRI -tractography.load det.tck

#use sift to filter tracks based on spherical harmonics
if [[ ! -f "det_weights.txt" ]]; then
	tcksift2 det.tck FOD.nii.gz -act 5TT.nii.gz det_weights.txt
	#tcksift2 prob.tck FOD.nii.gz -act 5TT.nii.gz prob_weights.txt
fi

#--------------------------------------------------------------------------------
## making individual glasser atlases
if [[ ! -f "glasser.nii.gz" ]]; then
	wb_command -label-to-volume-mapping $Llabels $Lmid T1_diff.nii.gz Lrois.nii.gz -ribbon-constrained $Lwhite $Lpial
	wb_command -label-to-volume-mapping $Rlabels $Rmid T1_diff.nii.gz Rrois.nii.gz -ribbon-constrained $Rwhite $Rpial
	#add 180 to left hemi labels to differentiate from right
	fslmaths Lrois.nii.gz -add 180 -thr 181 Lrois_plus180.nii.gz
	#merge left and right and do some trickery to remove any overlapping voxels
	fslmaths Lrois_plus180.nii.gz -add Rrois.nii.gz ROIs.nii.gz
	fslmaths Lrois.nii.gz -bin Lbin.nii.gz
	fslmaths Rrois.nii.gz -bin Rbin.nii.gz
	fslmaths Rbin.nii.gz -add Lbin.nii.gz Cbin.nii.gz
	fslmaths Cbin.nii.gz -thr 2 -binv overlap.nii.gz
	fslmaths overlap.nii.gz -mul ROIs.nii.gz glasser.nii.gz
fi

#--------------------------------------------------------------------------------
## generate connectome
if [[ ! -f "det_connectome.csv" ]]; then
	# make connectome (weighted by number of stremlines normalised by ROI voxel count and streamline length)
	tck2connectome det.tck glasser.nii.gz det_connectome.csv -scale_invlength -zero_diagonal -symmetric -tck_weights_in det_weights.txt
	tck2connectome det.tck glasser.nii.gz det_length_connectome.csv -scale_length -stat_edge mean
fi
#if [[ ! -f "prob_connectome.csv" ]]; then
#	tck2connectome prob.tck glasser.nii.gz prob_connectome.csv -scale_invlength -zero_diagonal -tck_weights_in prob_weights.txt
#	tck2connectome prob.tck glasser.nii.gz prob_length_connectome.csv -scale_length -stat_edge mean
#fi
# scaling by inverse of node volume -scale_invlength is odd when anatomically constrained, would make more sense to scale by # of gmwmi voxels
# scale by number of voxels in gmwmi in second step

#--------------------------------------------------------------------------------
#remove track files if connectome has been successfully generated
if [[ -f "det_connectome.csv" ]]; then
	rm det.tck
fi

#if [[ -f "prob_connectome.csv" ]]; then
#	rm prob.tck
#fi

fslmaths gmwmi.nii.gz -bin gmwmi_bin.nii.gz
fslstats -K glasser.nii.gz gmwmi_bin.nii.gz -V > voxel_count.txt
