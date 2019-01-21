#!/bin/bash -l
#mk list of commands and submit to queue using qbatch

module load python/3.6_ciftify_01
module load R/3.4.3
module load rstudio/1.1.414

cd /scratch/nforde/homotopic/bin
for subj in $(<RS_trio.txt); do
  echo Rscript temp_stab_ColeAnti.r ${subj}
done > RSstab_batch.txt

qbatch --walltime '10:00:00' -b sge --ppj 1 -c 15 -j 15 RSstab_batch.txt

#inPath=/projects/edickie/analysis/ABIDEI/hcp/NYU
#cd $inPath
#subjs=`ls -1d NYU*`
#
#for subj in $subjs; do
#  echo Rscript temp_stab_glasser_ABIDE.r ${subj}
#done > /scratch/nforde/homotopic/bin/R_qbatch_abide.txt
#
#cd /scratch/nforde/homotopic/bin/
#
#qbatch --walltime '03:00:00' -b sge --ppj 1 -c 1 -j 1 R_qbatch_abide.txt
