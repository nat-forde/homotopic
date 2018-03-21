
#!/usr/bin/
module load python/3.6_ciftify_01

# deterministic
#--------------------------------------------------------------------------------
cd /KIMEL/tigrlab/archive/data-2.0/OBI_POND/data/
SUBJECTS=`ls -1d MR160*`

for subj in $SUBJECTS; do
cd /KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD
out=/KIMEL/tigrlab/scratch/nforde/homotopic/POND/CSD/$subj
if [[ ! -d "${out}" ]]; then
	mkdir $out
fi
done


cd /KIMEL/tigrlab/scratch/nforde/homotopic/bin
for subj in $SUBJECTS; do
  echo bash CSD_scc.sh $subj
done > CSD_qbatch.txt

qbatch --walltime '24:00:00' -b pbs --ppj 1 -c 1 -j 1 --nodes 16 --mem 5G CSD_qbatch.txt


##-------------------------------------------------------------------------------
## Probabilistic
# cd /scratch/nforde/homotopic/POND/CSD/
# SUBJECTS=`ls -1d MR160*`
#
# cd /KIMEL/tigrlab/scratch/nforde/homotopic/bin
# for subj in $SUBJECTS; do
#   echo bash CSD_scc_prob.sh $subj
# done > CSD_prob_batch.txt
#
# qbatch --walltime '23:59:00' -b pbs --ppj 1 -c 1 -j 1 --nodes 16 --mem 5G CSD_prob_batch.txt
