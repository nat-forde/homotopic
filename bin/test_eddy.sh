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
outdir=/KIMEL/tigrlab/scratch/nforde/homotopic/POND/dtifit2/$subj

if [[ ! -d "${outdir}" ]]; then
  mkdir $outdir
fi

cd $tmpdir
outfile=$outdir/${subj}_data_eddy.nii.gz
# if [[ ! -f "${outfile}" ]] ; then
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
	bet b0 nodif_brain -m -R -f 0.3 #0.4
  bet Mag Mag_bet -R -f 0.5

	flirt -dof 6 -in Mag_bet -ref nodif_brain -omat xformMagVol_to_diff.mat -out Mag_bet_diff
	flirt -in FM -ref nodif_brain -applyxfm -init xformMagVol_to_diff.mat -out fieldmap_diff
  fslmaths fieldmap_diff.nii.gz -abs -bin fieldmap_diff_bin.nii.gz # making for qc
  fslmaths Mag_bet_diff.nii.gz -abs -bin Mag_bet_diff_bin.nii.gz # making for qc

	vols=$(fslval $dMRI dim4) #pull number of volumes from dMRI header
	indx=""
	for ((i=1; i<=${vols}; i+=1)); do indx="$indx 1"; done # assumes all volumes are aquired with the same phase encoding
	echo $indx > index.txt

	cat dwi.bval > bval.txt #bval and bvec files need to be in txt file
	cat dwi.bvec > bvec.txt

  if [ -f "single.nii.gz" ]; then
    printf "0 -1 0 0.0417443" > acqparams1.txt #TRT = effective echo spacing * (PE122-1)
    printf "0 -1 0 0.04208931" > acqparams2.txt #recip of bandwidth per pixel phase encoding direction
    printf "0 -1 0 0.03380941" > acqparams3.txt #effective echo spacing * (PE99-1)
    printf "0 -1 0 0.025529593" > acqparams4.txt #vendor echo spacing * ref lines PE38(from pdf) -1
  # elif [ -f "multi.nii.gz" ]; then
  #   printf "0 -1 0 0.0363005" > acqparams.txt #TRT # 0.03660054 #recip of bandwidth per pixel phase encoding direction
  # else echo $subj
	fi

	#eddy - finally
  # eddy_openmp --imain=$dMRI --mask=nodif_brain_mask --acqp=acqparams1.txt --index=index.txt --bvecs=bvec.txt --bvals=bval.txt --field=fieldmap_diff --out=data1b --repol
  # eddy_openmp --imain=$dMRI --mask=nodif_brain_mask --acqp=acqparams2.txt --index=index.txt --bvecs=bvec.txt --bvals=bval.txt --field=fieldmap_diff --out=data2b --repol
  # eddy_openmp --imain=$dMRI --mask=nodif_brain_mask --acqp=acqparams3.txt --index=index.txt --bvecs=bvec.txt --bvals=bval.txt --field=fieldmap_diff --out=data3b --repol
  eddy_openmp --imain=$dMRI --mask=nodif_brain_mask --acqp=acqparams4.txt --index=index.txt --bvecs=bvec.txt --bvals=bval.txt --field=fieldmap_diff --out=data4b --repol
#--mporder=6 --slspec=my_slspec.txt --s2v_niter=5 --s2v_lambda=1 --s2v_interp=trilinear # need cuda to impliment these

  #--repol replaces outliers with interpolated data
	#--residuals will output a residual nifti

  # cat data.eddy_rotated_bvecs > eddy_bvecs.txt

  #dtifit --data=data.nii.gz --mask=nodif_brain_mask --bvecs=eddy_bvecs.txt --bvals=bval.txt --out=${subj}_dtifit

  cp data1b.nii.gz $outdir/${subj}_data1b_eddy.nii.gz
  cp data2b.nii.gz $outdir/${subj}_data2b_eddy.nii.gz
  cp data3b.nii.gz $outdir/${subj}_data3b_eddy.nii.gz
  cp data4b.nii.gz $outdir/${subj}_data4b_eddy.nii.gz

  # cp data.eddy_rotated_bvecs $outdir/eddy_bvecs
  # cp dwi.bval $outdir/bvals
  # cp nodif_brain_mask.nii.gz $outdir/
  # cp nodif_brain.nii.gz $outdir/
  # cp b0.nii.gz $outdir/
  # cp ${subj}_dtifit* $outdir/
  # cp fieldmap_diff_bin.nii.gz $outdir/
  # cp Mag_bet_diff_bin.nii.gz $outdir/

# fi
