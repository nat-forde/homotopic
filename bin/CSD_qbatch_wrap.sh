#!/usr/bin/bash -l
module load python/3.6_ciftify_01

# deterministic
#--------------------------------------------------------------------------------
cd /KIMEL/tigrlab/scratch/nforde/homotopic/bin


for subj in $(<multi.txt); do
	outdir=/KIMEL/tigrlab/projects/nforde/POND/CSD/$subj
	if [[ ! -d "${outdir}" ]] ; then
		mkdir $outdir
	fi

	outfile=/KIMEL/tigrlab/projects/nforde/POND/CSD/$subj/prob_DK.csv
	if [[ ! -f "${outfile}" ]] ; then
		echo bash CSD_multi.sh $subj
	fi
done > CSD_qbatch.txt

#qbatch  --walltime '48:00:00' -b pbs --ppj 1 -c 1 -j 1 --nodes 1 -o "-l feature=bigmem"  CSD_qbatch.txt

# qbatch --walltime '24:00:00' -b pbs --ppj 20 -c 1 -j 1 --nodes 1 -o "-l mem=130g" CSD_qbatch.txt

qbatch --walltime '24:00:00' -b slurm --ppj 20 -c 2 -j 2 --mem 30G --logdir /KIMEL/tigrlab/scratch/nforde/homotopic/bin/CSDlogs CSD_qbatch.txt



#submit SCC
#qbatch --walltime '24:00:00' -b slurm --ppj 20 -c 1 -j 1 -o "--nodes=1" -o "--cores-per-socket=20" --logdir /KIMEL/tigrlab/scratch/nforde/HBN/bin/CSDlogs CSD_qbatch.txt


# Submitting to makes SH residuals
cd /projects/nforde/POND/dtifit/
SUBJECTS=`ls -d sub*`
for subj in $SUBJECTS; do
	outfile=/projects/nforde/POND/dtifit/$subj/residualSH_masked.nii.gz
	if [[ ! -f "${outfile}" ]] ; then
	echo bash dMRI_SH_residuals.sh $subj
	fi
done > /scratch/nforde/homotopic/bin/mkSH_residuls.txt


cd /scratch/nforde/homotopic/bin
# on the SCC
qbatch --walltime '02:00:00' -b slurm --ppj 8 -c 1 -j 1 --logdir /KIMEL/tigrlab/scratch/nforde/homotopic/bin/res mkSH_residuls.txt
#submit local - don't do this it slow everything down and makes Jerry sad
cat mkSH_residuls.txt | xargs -I {} sbatch -p low-moby --time=00:30:00 --export=ALL --wrap "{}"
