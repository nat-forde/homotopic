#!/usr/bin/bash -l
module load python/3.6_ciftify_01

# deterministic
#--------------------------------------------------------------------------------
cd /KIMEL/tigrlab/scratch/nforde/homotopic/bin


for subj in $(<multi.txt); do
cd /KIMEL/tigrlab/projects/nforde/POND/CSD
out=/KIMEL/tigrlab/projects/nforde/POND/CSD/$subj
if [[ ! -d "${out}" ]]; then
	mkdir $out
fi
done

cd /KIMEL/tigrlab/scratch/nforde/homotopic/bin
for subj in $(<multi.txt); do
out=/KIMEL/tigrlab/projects/nforde/POND/CSD/$subj/prob_DK.csv
if [[ ! -f "${out}" ]]; then
	echo $subj
fi
done > CSD_multi_undone.txt


cd /KIMEL/tigrlab/scratch/nforde/homotopic/bin
for subj in $(<CSD_multi_undone.txt); do
  echo bash CSD_multi.sh $subj
done > CSD_qbatch.txt

#qbatch  --walltime '48:00:00' -b pbs --ppj 1 -c 1 -j 1 --nodes 1 -o "-l feature=bigmem"  CSD_qbatch.txt

# qbatch --walltime '24:00:00' -b pbs --ppj 20 -c 1 -j 1 --nodes 1 -o "-l mem=130g" CSD_qbatch.txt

qbatch --walltime '24:00:00' -b slurm --ppj 20 -c 5 -j 5 --logdir /KIMEL/tigrlab/scratch/nforde/homotopic/bin/CSDlogs CSD_qbatch.txt
