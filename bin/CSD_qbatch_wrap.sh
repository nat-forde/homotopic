
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

#qbatch  --walltime '48:00:00' -b pbs --ppj 1 -c 1 -j 1 --nodes 1 -o "-l feature=bigmem"  CSD_qbatch.txt

qbatch --walltime '05:00:00' -b pbs --ppj 20 -c 1 -j 1 --nodes 1 -o "-l mem=130g" CSD_qbatch.txt
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
# qbatch --walltime '08:00:00' -b pbs --ppj 20 -c 1 -j 1 --nodes 1 -o "-l mem=130g" CSD_prob_batch.txt
