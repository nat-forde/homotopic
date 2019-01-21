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

#for raw concatenated data
indir=/KIMEL/tigrlab/projects/nforde/COMPULS/dwi/$subj
outdir=/KIMEL/tigrlab/projects/nforde/COMPULS/dtifit/$subj
qcdir=/KIMEL/tigrlab/projects/nforde/COMPULS/dtifit/$subj/all

if [[ ! -d "${outdir}" ]]; then
  mkdir $outdir
fi
if [[ ! -d "${qcdir}" ]]; then
  mkdir $qcdir
fi

cd $tmpdir
# outfile=$outdir/data.nii.gz
# if [[ ! -f "${outfile}" ]] ; then
  cp ${indir}/dwi_single_concat.nii.gz $tmpdir/single.nii.gz
  cp ${indir}/dwi.bval $tmpdir
  cp ${indir}/dwi.bvec $tmpdir

  dwidenoise single.nii.gz dMRI_denoise.nii.gz
  mrresize dMRI_denoise.nii.gz -scale 2 dMRI_up.nii.gz

	fslroi dMRI_up.nii.gz b0 0 1
	bet b0 nodif_brain -m -R -f 0.3 #0.4

	vols=$(fslval single.nii.gz dim4) #pull number of volumes from dMRI header
	indx=""
	for ((i=1; i<=${vols}; i+=1)); do indx="$indx 1"; done # assumes all volumes are aquired with the same phase encoding
	echo $indx > index.txt

	cat dwi.bval > bval.txt #bval and bvec files need to be in txt file
	cat dwi.bvec > bvec.txt

  printf "0 -1 0 0.05" > acqparams.txt ## of ref lines PE (38) -1 * echo spacing (vendor)

	#eddy - finally
	eddy_openmp --imain=dMRI_up.nii.gz --mask=nodif_brain_mask --acqp=acqparams.txt --index=index.txt --bvecs=bvec.txt --bvals=bval.txt --out=data --repol --residuals --cnr_maps
	#--repol replaces outliers with interpolated data
	#--residuals will output a residual 4D nifti

  cat data.eddy_rotated_bvecs > eddy_bvecs.txt
  fslroi data.nii.gz b0 0 1
	bet b0 nodif_brain -m -R -f 0.3

  dtifit --data=data.nii.gz --mask=nodif_brain_mask --bvecs=eddy_bvecs.txt --bvals=bval.txt --out=${subj}_dtifit --sse

  cp * $qcdir/
  cd $qcdir
  mv data.nii.gz data.eddy_rotated_bvecs ${subj}_dtifit* dwi.bval nodif_brain_mask.nii.gz nodif_brain.nii.gz b0.nii.gz /${outdir}/

# fi
