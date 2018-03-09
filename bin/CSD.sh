
#!/usr/bin/

module load MRtrix3/20180123
module load FSL/5.0.9

#--------------------------------------------------------------------------------
## mrtrix3 tractography

cd /archive/data-2.0/OBI_POND/data/
#SUBJECTS=`ls -1d MR160*`

cd /scratch/nforde/homotopic/POND/CSD
#for subj in $SUBJECTS; do
for subj in 'MR160-088-0419-01' 'MR160-088-0462-01' 'MR160-088-0470-01' 'MR160-088-0473-01' 'MR160-088-0476-01' ; do
	out=/scratch/nforde/homotopic/POND/CSD/$subj
	if [[ ! -d "${out}" ]]; then
		mkdir $out
	fi
	cd ${out}

	# input file
	dMRI=/archive/data-2.0/OBI_POND/data/${subj}/*_ec.nii
	brain_mask=/archive/data-2.0/OBI_POND/data/${subj}/${subj}_mask.nii
	#T1=/archive/data-2.0/OBI_POND/data/$subj/${subj}_T1.nii
	FA=/archive/data-2.0/OBI_POND/data/$subj/DTIfit/${subj}_FA.nii.gz #/*_FA.nii.gz worked for most this is for a subset that had multiple FA files
	bval=/archive/data-2.0/OBI_POND/data/$subj/*.bval
	bvec=/archive/data-2.0/OBI_POND/data/$subj/*.bvec

	if [[ ! -f "tracks.tck" ]]; then
		echo $subj response func estimation...
		dwi2response tournier $dMRI -fslgrad $bvec $bval response.txt -force
		#shview response.txt

  	echo $subj CSD...
		dwi2fod csd $dMRI response.txt FOD.nii.gz -mask $brain_mask -fslgrad $bvec $bval -force
		#mrview $dMRI -odf.load_sh FOD.nii.gz

		#anatomically constrained tractography (ACT) use 5ttgen script
		#register T1 to diffusion space first
		#fslroi $dMRI b0 0 1
		#flirt -dof 6 -in $T1 -ref b0.nii.gz -omat xformT1_to_diff.mat -out T1_diff
  	#echo $subj 5tt seg...
		#5ttgen fsl $T1 5TT #-t2 <T2 image optional>

		fslmaths $FA -thr 0.15 -bin FAmask
  	echo $subj generating streamlines...
  	tckgen FOD.nii.gz tracks.tck -seed_image FAmask.nii.gz -mask $brain_mask -select 100000
# can use -act instead of -mask (anatomically constrained tractography)
# -select <number of stremlines> default is 5000
#mrview $dMRI -tractography.load tracks.tck
	fi
done
