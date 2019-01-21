#!/usr/bin/env bash
#
# running eddy_openmp
# moving output to dtifit directory

module load MRtrix3/3.0_RC2
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


indir=/KIMEL/tigrlab/projects/nforde/POND/dwi/$subj
outdir=/KIMEL/tigrlab/projects/nforde/POND/dtifit/$subj
# qcdir=/KIMEL/tigrlab/projects/nforde/POND/dtifit/$subj/all

if [[ ! -d "${outdir}" ]]; then
  mkdir $outdir
fi
if [[ ! -d "${qcdir}" ]]; then
  mkdir $qcdir
fi

cd $tmpdir
outfile=$outdir/data.nii.gz
# if [[ ! -f "${outfile}" ]] ; then
  # cp ${indir}/reg_dwi_single.nii.gz $tmpdir/single.nii.gz
  cp ${indir}/dwi_multi_concat.nii.gz $tmpdir/multi.nii.gz
  # cp ${indir}/reg_dwi_multi_up.nii.gz $tmpdir/dMRI_up.nii.gz ##
  cp ${indir}/dwi.bval $tmpdir
  cp ${indir}/dwi.bvec $tmpdir
  cp /KIMEL/tigrlab/projects/nforde/POND/fmap/$subj/dwi_fieldmap_Hz.nii.gz $tmpdir/FM.nii.gz
  cp /KIMEL/tigrlab/external/pond/data/$subj/ses-01/fmap/$subj\_ses-01_magnitude1.nii.gz $tmpdir/Mag.nii.gz
  cp /KIMEL/tigrlab/external/pond/data/$subj/ses-01/fmap/$subj\_ses-01_run-01_magnitude1.nii.gz $tmpdir/Mag.nii.gz
cd $outdir
cp data.nii.gz dwi.bval eddy_bvecs.txt bval.txt $tmpdir/
cd $tmpdir

	if [ -f "single.nii.gz" ]; then
		dMRI=single.nii.gz
  elif [ -f "multi.nii.gz" ]; then
    dMRI=multi.nii.gz
  else echo $subj no dwi
	fi

  dwidenoise $dMRI dMRI_denoise.nii.gz
  mrresize dMRI_denoise.nii.gz -scale 2 dMRI_up.nii.gz

#### first vol isn't always a B0 so need to find which is the first
  for n in `seq 1 10`; do
    if [ $(cut -d' ' -f${n} dwi.bval) -eq 0 ]; then
      x=$(expr $n - 1)
      break
    fi
  done

  fslroi dMRI_up.nii.gz b0 $x 1 ###
  bet b0 nodif_brain -m -R -f 0.3 #0.4
  bet Mag Mag_bet -R -f 0.5

	flirt -dof 6 -in Mag_bet -ref nodif_brain -omat xformMagVol_to_diff.mat -out Mag_bet_diff
	flirt -in FM -ref nodif_brain -applyxfm -init xformMagVol_to_diff.mat -out fieldmap_diff
  fslmaths fieldmap_diff.nii.gz -abs -bin fieldmap_diff_bin.nii.gz # making for qc
  fslmaths Mag_bet_diff.nii.gz -abs -bin Mag_bet_diff_bin.nii.gz # making for qc

	vols=$(fslval dMRI_up.nii.gz dim4) #pull number of volumes from dMRI header
	indx=""
	for ((i=1; i<=${vols}; i+=1)); do indx="$indx 1"; done # assumes all volumes are aquired with the same phase encoding
	echo $indx > index.txt

	cat dwi.bval > bval.txt #bval and bvec files need to be in txt file
	cat dwi.bvec > bvec.txt

  if [ -f "single.nii.gz" ]; then
    printf "0 -1 0 0.025529593" > acqparams.txt # # of ref lines PE (38) -1 * echo spacing (vendor)
  elif [ -f "multi.nii.gz" ]; then
    printf "0 -1 0 0.022200333" > acqparams.txt #TRT # 0.03660054 #recip of bandwidth per pixel phase encoding direction
  else echo $subj
	fi

	#eddy - finally
	eddy_openmp --imain=dMRI_up.nii.gz --mask=nodif_brain_mask --acqp=acqparams.txt --index=index.txt --bvecs=bvec.txt --bvals=bval.txt --field=fieldmap_diff --out=data --repol --residuals --cnr_maps
	#--repol replaces outliers with interpolated data
	#--residuals will output a residual nifti

  cat data.eddy_rotated_bvecs > eddy_bvecs.txt

  fslroi data.nii.gz b0 $x 1
	bet b0 nodif_brain -m -R -f 0.3

  dtifit --data=data.nii.gz --mask=nodif_brain_mask --bvecs=eddy_bvecs.txt --bvals=bval.txt --out=${subj}_dtifit --sse

  mv * ${outdir}/

# fi
