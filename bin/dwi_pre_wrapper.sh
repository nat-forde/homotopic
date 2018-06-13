#!/usr/bin/
module load python/3.6_ciftify_01

#--------------------------------------------------------------------------------

cd /KIMEL/tigrlab/scratch/nforde/homotopic/POND/dwi
SUBJECTS=`ls -d sub-*`

cd /KIMEL/tigrlab/scratch/nforde/homotopic/bin
for subj in $SUBJECTS; do
  echo bash dMRI_pre_POND.sh $subj
done > dwi_pre_batch.txt

qbatch --walltime '06:00:00' -b pbs --ppj 8 -c 5 -j 5 --nodes 1 --logdir /KIMEL/tigrlab/scratch/nforde/homotopic/bin/Eddylogs dwi_pre_batch.txt
