
#!/usr/bin/

module load MRtrix3/3.0_RC2
module load FSL/5.0.9
module load connectome-workbench/1.2.3

#running probability tractography after deterministic so most files have already been generated

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
cp /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/FOD.nii.gz $tmpdir/
cp /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/5TT.nii.gz $tmpdir/
cp /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/gmwmi.nii.gz $tmpdir/
cp /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/glasser.nii.gz $tmpdir/


#--------------------------------------------------------------------------------
## mrtrix3 CSD and tractography
if [[ ! -f "/KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/prob_connectome.csv" ]]; then

# tractography probabilistic
	#generate tracks 100million should be doable on the cluster # Check computing required and storage space
	tckgen FOD.nii.gz prob.tck -act 5TT.nii.gz -seed_gmwmi gmwmi.nii.gz -step 0.5 -angle 30 -minlength 10 -select 50000000 #probabilistic is default
#mrview $dMRI -tractography.load det.tck

#use sift to filter tracks based on spherical harmonics
  tcksift2 prob.tck FOD.nii.gz -act 5TT.nii.gz prob_weights.txt

#--------------------------------------------------------------------------------
## generate connectome
	# make connectome (weighted by number of stremlines normalised by streamline length)
	tck2connectome prob.tck glasser.nii.gz prob_connectome.csv -scale_invlength -zero_diagonal -tck_weights_in prob_weights.txt
	tck2connectome prob.tck glasser.nii.gz prob_length_connectome.csv -scale_length -stat_edge mean

##copy required files
	cp prob_connectome.csv /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/
	cp prob_length_connectome.csv /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj/

fi
