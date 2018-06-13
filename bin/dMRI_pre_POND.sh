#!/usr/bin/env bash
#
# running eddy_openmp
# moving output to dtifit directory

module load FSL/5.0.10

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
trap cleanup_ramdisk 0


indir=/KIMEL/tigrlab/scratch/nforde/homotopic/POND/dwi/$subj
outdir=/KIMEL/tigrlab/scratch/nforde/homotopic/POND/dtifit/$subj

if [[ ! -d "${outdir}" ]]; then
  mkdir $outdir
fi

cd $tmpdir
outfile=$outdir/${subj}_data_eddy.nii.gz
if [[ ! -f "${outfile}" ]] ; then
  cp ${indir}/dwi_single_concat.nii.gz $tmpdir/single.nii.gz
  cp ${indir}/dwi_multi_concat.nii.gz $tmpdir/multi.nii.gz
  cp ${indir}/dwi.bval $tmpdir
  cp ${indir}/dwi.bvec $tmpdir
  cp /KIMEL/tigrlab/scratch/nforde/homotopic/POND/fmap/$subj/dwi_fieldmap_Hz.nii.gz $tmpdir/FM.nii.gz
  cp /KIMEL/tigrlab/external/pond/data/$subj/ses-01/fmap/$subj\_ses-01_magnitude1.nii.gz $tmpdir/Mag.nii.gz
  cp /KIMEL/tigrlab/external/pond/data/$subj/ses-01/fmap/$subj\_ses-01_run-01_magnitude1.nii.gz $tmpdir/Mag.nii.gz


	if [ -f "single.nii.gz" ]; then
		dMRI=single.nii.gz
  elif [ -f "multi.nii.gz" ]; then
    dMRI=multi.nii.gz
  else echo $subj no dwi
	fi

	fslroi $dMRI b0 0 1
	bet b0 nodif_brain -m -R -f 0.4

	flirt -dof 6 -in Mag -ref nodif_brain -omat xformMagVol_to_diff.mat
	flirt -in FM -ref nodif_brain -applyxfm -init xformMagVol_to_diff.mat -out fieldmap_diff

	vols=$(fslval $dMRI dim4) #pull number of volumes from dMRI header
	indx=""
	for ((i=1; i<=${vols}; i+=1)); do indx="$indx 1"; done # assumes all volumes are aquired with the same phase encoding
	echo $indx > index.txt

	cat dwi.bval > bval.txt #bval and bvec files need to be in txt file
	cat dwi.bvec > bvec.txt

  if [ -f "single.nii.gz" ]; then
    printf "0 -1 0 0.0417443" > acqparams.txt
  elif [ -f "multi.nii.gz" ]; then
    printf "0 -1 0 0.0363005" > acqparams.txt
  else echo $subj
	fi

	#eddy - finally
	eddy_openmp --imain=$dMRI --mask=nodif_brain_mask --acqp=acqparams.txt --index=index.txt --bvecs=bvec.txt --bvals=bval.txt --field=fieldmap_diff --out=data --repol
	#--repol replaces outliers with interpolated data
	#--residuals will output a residual nifti

  cat data.eddy_rotated_bvecs > eddy_bvecs.txt

  dtifit --data=data.nii.gz --mask=nodif_brain_mask --bvecs=eddy_bvecs.txt --bvals=bval.txt --out=${subj}_dtifit

  cp data.nii.gz $outdir/${subj}_data_eddy.nii.gz
  cp data.eddy_rotated_bvecs $outdir/eddy_bvecs
  cp dwi.bval $outdir/bvals
  cp nodif_brian_mask.nii.gz $outdir/
  cp ${subj}_dtifit* $outdir/

fi
