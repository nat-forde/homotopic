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

indir=/KIMEL/tigrlab/projects/nforde/POND/CSD/$subj
outdir=/KIMEL/tigrlab/projects/nforde/POND/CSDnew/$subj

# cp input file
#subject specific
cp $indir/gmwmi.nii.gz $tmpdir/
cp $indir/FOD.nii.gz $tmpdir/
cp $indir/glasser.nii.gz $tmpdir/

#--------------------------------------------------------------------------------
########### ------------ MRtrix Tractography ---------- ###############

#anatomically constrained tractography (ACT) use 5ttgen script ## Not using ACT (doesn't let tracts intersect with GM ROIs properly) Still generating the gmwmi to seed from
fslmaths gmwmi.nii.gz -bin gmwmi_bin.nii.gz

# probabilistic
tckgen FOD.nii.gz prob.tck -seed_image gmwmi_bin.nii.gz -select 5000000 ## seeding from a binarised gmwmi

#use sift to filter tracks based on spherical harmonics
tcksift2 prob.tck FOD.nii.gz prob_weights.txt

########### ------------ EXTRACT MATRICES ---------- ###############
## generate connectome
tck2connectome prob.tck glasser.nii.gz prob_glasser.csv -assignment_radial_search 2 -scale_invnodevol -scale_invlength -zero_diagonal -symmetric -tck_weights_in prob_weights.txt
tck2connectome prob.tck glasser.nii.gz prob_length_glasser.csv -assignment_radial_search 2 -scale_length -stat_edge mean
##-------------------------------------------------------------------------------

##copy required files
cp *.csv $outdir/
