#!/usr/bin/env bash


module load FSL/5.0.10
module load R/3.4.3
module load rstudio/1.1.414

#select and merge dwi niftis

# cd /external/pond/data/
# cd /scratch/nforde/homotopic/POND/dwi/
# SUBJECTS=`ls -d sub-*`

cd /scratch/nforde/homotopic/bin
for subj in $(<single.txt); do
	if [[ -d "/external/pond/data/$subj/ses-01/dwi" ]]; then
    inDir=/external/pond/data/$subj/ses-01/dwi
    if [[ ! -d "/projects/nforde/POND/dwi/$subj" ]]; then
    	mkdir /projects/nforde/POND/dwi/$subj
    fi

    cd /projects/nforde/POND/dwi/$subj

    #single
		if [[ ! -f dwi_single_concat.nii.gz ]]; then
    	if [ -f $inDir/$subj\_ses-01_acq-singleshell19dir_dwi.nii.gz ] & [ $(fslval $inDir/$subj\_ses-01_acq-singleshell19dir_dwi.nii.gz dim4) -ge 22 ]; then
      	dir19=$inDir/$subj\_ses-01_acq-singleshell19dir_dwi

      	if [ -f $inDir/$subj\_ses-01_acq-singleshell20dir_dwi.nii.gz ] & [ $(fslval $inDir/$subj\_ses-01_acq-singleshell20dir_dwi.nii.gz dim4) -ge 23 ]; then
        	dir20=$inDir/$subj\_ses-01_acq-singleshell20dir_dwi

        	if [ -f $inDir/$subj\_ses-01_acq-singleshell21dir_dwi.nii.gz ] &  [ $(fslval $inDir/$subj\_ses-01_acq-singleshell21dir_dwi.nii.gz dim4) -ge 24 ]; then
          	dir21=$inDir/$subj\_ses-01_acq-singleshell21dir_dwi

          	fslmerge -t dwi_single_concat.nii.gz ${dir19}.nii.gz ${dir20}.nii.gz ${dir21}.nii.gz

          	Rscript /scratch/nforde/homotopic/bin/bind_bvals_bvecs.r $subj ${dir19}.bval ${dir20}.bval ${dir21}.bval
          	Rscript /scratch/nforde/homotopic/bin/bind_bvals_bvecs.r $subj ${dir19}.bvec ${dir20}.bvec ${dir21}.bvec
        	fi
      	fi
    	fi
		fi
	fi
done

cd /scratch/nforde/homotopic/bin
for subj in $(<multi.txt); do
	if [[ -d "/external/pond/data/$subj/ses-01/dwi" ]]; then
    inDir=/external/pond/data/$subj/ses-01/dwi
    if [[ ! -d "/projects/nforde/POND/dwi/$subj" ]]; then
    	mkdir /projects/nforde/POND/dwi/$subj
    fi

    cd /projects/nforde/POND/dwi/$subj

		if [[ ! -f dwi_multi_concat.nii.gz ]]; then
    	if [ -f $inDir/$subj\_ses-01_acq-multishell30dir_dwi.nii.gz ] & [ $(fslval $inDir/$subj\_ses-01_acq-multishell30dir_dwi.nii.gz dim4) -ge 35 ]; then
      	dir30=$inDir/$subj\_ses-01_acq-multishell30dir_dwi

      	if [ -f $inDir/$subj\_ses-01_acq-multishell40dir_dwi.nii.gz ] & [ $(fslval $inDir/$subj\_ses-01_acq-multishell40dir_dwi.nii.gz dim4) -ge 45 ]; then
        	dir40=$inDir/$subj\_ses-01_acq-multishell40dir_dwi

        	if [ -f $inDir/$subj\_ses-01_acq-multishell60dir_dwi.nii.gz ] & [ $(fslval $inDir/$subj\_ses-01_acq-multishell60dir_dwi.nii.gz dim4) -ge 66 ]; then
          	dir60=$inDir/$subj\_ses-01_acq-multishell60dir_dwi

          	fslmerge -t dwi_multi_concat.nii.gz $dir30.nii.gz $dir40.nii.gz $dir60.nii.gz

          	Rscript /scratch/nforde/homotopic/bin/bind_bvals_bvecs.r $subj $dir30.bval $dir40.bval $dir60.bval
          	Rscript /scratch/nforde/homotopic/bin/bind_bvals_bvecs.r $subj $dir30.bvec $dir40.bvec $dir60.bvec
        	fi
      	fi
    	fi
		fi
	fi

done

# subj=sub-1050345
# inDir=/external/pond/data/$subj/ses-01/dwi
# cd /projects/nforde/POND/dwi/$subj

# dir19=$inDir/$subj\_ses-01_acq-singleshell19dir_dwi
# dir20=$inDir/$subj\_ses-01_acq-singleshell20dir_dwi
# dir21=$inDir/$subj\_ses-01_acq-singleshell21dir_run-02_dwi
# fslmerge -t dwi_single_concat.nii.gz ${dir19}.nii.gz ${dir20}.nii.gz ${dir21}.nii.gz
# Rscript /scratch/nforde/homotopic/bin/bind_bvals_bvecs.r $subj $dir19.bval $dir20.bval $dir21.bval
# Rscript /scratch/nforde/homotopic/bin/bind_bvals_bvecs.r $subj $dir19.bvec $dir20.bvec $dir21.bvec
#
# dir30=$inDir/$subj\_ses-01_acq-multishell30dir_dwi
# dir40=$inDir/$subj\_ses-01_acq-multishell40dir_dwi
# dir60=$inDir/$subj\_ses-01_acq-multishell60dir_dwi
# fslmerge -t dwi_multi_concat.nii.gz $dir30.nii.gz $dir40.nii.gz $dir60.nii.gz
# Rscript /scratch/nforde/homotopic/bin/bind_bvals_bvecs.r $subj $dir30.bval $dir40.bval $dir60.bval
# Rscript /scratch/nforde/homotopic/bin/bind_bvals_bvecs.r $subj $dir30.bvec $dir40.bvec $dir60.bvec

# sub-0880019 use 19 run-02
# sub-0880229 use 19 run-02
# sub-0880470 use 21 run-02
# sub-0880473 use 21 run-01
# sub-0880476 use 19 run-01
# sub-0880794 use 40 run-02
# sub-1050027 use 19 run-02, 20 run-02, 21 run -02
# sub-1050093 use 20 run-01
# sub-1050098 use 19 run-02, 20 run-02, 21 run-02
# sub-1050325 use 21 run-02
# sub-1050371 use 19 run-02
# sub-1050430 exclude
# sub-1050512 use 40 run-03
# sub-1050518 use 60 run-02
# sub-1050548 use 30 run-02, 40 run-02
# sub-1050608 use 30 run-02
# sub-1050701 use 60 run-02
