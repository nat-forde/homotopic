#!/usr/bin/env bash
module load python/3.6_ciftify_01

#--------------------------------------------------------------------------------

# cd /KIMEL/tigrlab/scratch/nforde/homotopic/POND/dwi
# SUBJECTS=`ls -d sub-*`

cd /KIMEL/tigrlab/scratch/nforde/homotopic/bin
for subj in $(<multi.txt); do
  echo bash dMRI_pre_POND_multi.sh $subj
done > dwi_pre_batch.txt

qbatch --walltime '36:00:00' -b slurm --ppj 8 -c 1 -j 1 --nodes 1 --logdir /KIMEL/tigrlab/scratch/nforde/homotopic/bin/Eddylogs dwi_pre_batch.txt

qbatch --walltime '01:00:00' -b slurm --ppj 8 -c 20 -j 20 --nodes 1 --logdir /KIMEL/tigrlab/scratch/nforde/homotopic/bin/Eddylogs dwi_pre_batch.txt

## multi data require much longer
## single; 24hrs in chunks of 5 works
