#!/usr/bin/env python

##depreciated! Use jerry's script if you are going to do this (our blind evaluation showed it's not hepful - more smoothing not improvement in quality)
import numpy as np
import pandas as pd
import time
import os

# import pdb; pdb.set_trace() #debugging interactive
# script to do some DTI
# export PATH=/archive/code/python_2.7.13_datman_01/bin/:$PATH
# module load AFNI
# module load minc-toolkit/1.9.10
# module load FSL/5.0.10
## you should only need to edit things in this secion
recon_dir = "/projects/nforde/POND/dwi/"  # this is where the reconstructed data will go
process_dir = "/projects/nforde/POND/dwi/"  # this is where the processed data will go
# b0_ref = 0   # which b0 to align all other volumes to
correctBvecs = "/scratch/nforde/homotopic/bin/correctBvecs_new.py"  # a .py file that is called during processing
# MNI_fname = "$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz"    # standard space image

# the below S file needs to be formatted correctly, check an example file

#S_fname = "/projects/gjacobs/POND/Running_DTIPrep/pond_DTI_metadata20151118.csv"
S_fname = "/scratch/nforde/homotopic/bin/single_subs.csv"
# dcm_dir = "/scratch/nforde/remove/POND/data/dcm/"   # where the dicoms live (study folder)
# dcm_type = ""   # .dcm or .IMA or leave blank if you're confident there are no reconstructed files in the directory


    # load in S-file and parse it
S_data = pd.read_csv(S_fname, skipinitialspace = True, dtype = np.str_)

col_names = S_data.columns.values

    #  make list of subject IDs
num_sub = len(S_data.subj_ID)
subjects = S_data.subj_ID

print('About to run for loop with all subjects')

#for i in range(num_sub):
# subjects = ['sub-0880278']
# i = 0
for i in range(num_sub):
    print(subjects[i])
    try:
        # set up subject directories
        # cmd = 'mkdir -p ' + recon_dir + subjects[i]
        # os.system(cmd)
        #
        # cmd = 'mkdir -p ' + process_dir + subjects[i]
        # os.system(cmd)
        tmp_dir = process_dir + subjects[i] + '/tmp/'
        cmd = 'mkdir -p ' + tmp_dir
        os.system(cmd)
        ## concatenated niis
        concat_nii = "/projects/nforde/POND/dwi"

        recon_sub = recon_dir + subjects[i] + '/' + subjects[i]
        process_sub = concat_nii + '/' + subjects[i] + '/'

        dti_total = process_sub + 'dwi_single_concat.nii.gz'
        #dti_total = process_sub + '_dti_total.nii'

        # split the 4d file into bunch of 3d files for running individual brain
        # transformations on each volume
        cmd = 'fslsplit ' + dti_total + ' ' + tmp_dir + 'dti_split_'
        os.system(cmd);

        ## align to closest b0
        bval_total = process_sub + 'dwi.bval'
        f=open(bval_total, 'r')
        bval_raw = f.read().lstrip().split(' ')
        f.closed
        bval_total = [int(float(b)) for b in bval_raw]

        ## directing to the bvec file
        bvec_total = process_sub + 'dwi.bvec'
        bvec_total = np.genfromtxt(process_sub + 'dwi.bvec')

        # f=open(bvec_total, 'r')
        # bvec_raw = f.read().replace("0\n0", "0 0").strip().split(' ')
        # f.closed
        # bvec_total = [float(b) for b in bvec_raw]

        # find which volumes are b0
        b0_ind = [val for val in range(len(bval_total)) if bval_total[val] == 0]
        print('Sorted B0_ind: {}').format(sorted(b0_ind))
        b0_ref = sorted(b0_ind)[0]

        #print(bval_total)print(subjects[i])
        # set up subject directories
        # cmd = 'mkdir -p ' + recon_dir + subjects[i]
        # os.system(cmd)
        #
        # cmd = 'mkdir -p ' + process_dir + subjects[i]
        # os.system(cmd)
        tmp_dir = process_dir + subjects[i] + '/tmp/'
        cmd = 'mkdir -p ' + tmp_dir
        os.system(cmd)
        ## concatenated niis
        concat_nii = "/projects/nforde/POND/dwi"

        recon_sub = recon_dir + subjects[i] + '/' + subjects[i]
        process_sub = concat_nii + '/' + subjects[i] + '/'

        dti_total = process_sub + 'dwi_single_concat.nii.gz'
        #dti_total = process_sub + '_dti_total.nii'

        # split the 4d file into bunch of 3d files for running individual brain
        # transformations on each volume
        cmd = 'fslsplit ' + dti_total + ' ' + tmp_dir + 'dti_split_'
        os.system(cmd);

        ## align to closest b0
        bval_total = process_sub + 'dwi.bval'
        f=open(bval_total, 'r')
        bval_raw = f.read().lstrip().split(' ')
        f.closed
        bval_total = [int(float(b)) for b in bval_raw]

        ## directing to the bvec file
        bvec_total = process_sub + 'dwi.bvec'
        bvec_total = np.genfromtxt(process_sub + 'dwi.bvec')

        # f=open(bvec_total, 'r')
        # bvec_raw = f.read().replace("0\n0", "0 0").strip().split(' ')
        # f.closed
        # bvec_total = [float(b) for b in bvec_raw]

        # find which volumes are b0
        b0_ind = [val for val in range(len(bval_total)) if bval_total[val] == 0]
        print('Sorted B0_ind: {}').format(sorted(b0_ind))
        b0_ref = sorted(b0_ind)[0]

        #print(bval_total)
        print("bvec_total")
        print(bvec_total)

        print("b0_ind")
        print(b0_ind)

        dti_ec = process_sub + 'reg_dwi_single.nii' ##name registered dwi output file
        num_vol = len(bval_total);

        ## Testing if this works earlier rather than later
        for j in range(num_vol):
            if j == b0_ref:
                bvec_tmp = bvec_total[:,j]
                break

        # go through each volume and flirt it to reference volume
        print('Performing registrtion correction to volume: ' + str(b0_ref)) ## just registering them, b0_red is 0

        # first go through and register b0s to the reference b0
        for j in range(len(b0_ind)):

            tmp_reg = tmp_dir + 'dti_reg_' + "{0:04d}".format(b0_ind[j]) + '.nii.gz'
            vol_fname = tmp_dir + 'dti_split_' + "{0:04d}".format(b0_ind[j]) + '.nii.gz'
            xfm_fname = tmp_dir + 'dti_reg_' + "{0:04d}".format(b0_ind[j]) + '.xfm'

            if b0_ind[j] == b0_ref:
                cmd = 'cp ' + vol_fname + ' ' + tmp_reg
                os.system(cmd);

            else:
                ref_ind = b0_ref
                ref_fname = tmp_dir + 'dti_split_' + "{0:04d}".format(ref_ind) + '.nii.gz'
                cmd = 'flirt -in ' + vol_fname + ' -ref ' + ref_fname + ' -out ' +  tmp_reg + \
                    ' -nosearch -paddingsize 1 -omat ' + xfm_fname + ' -dof 6'
                os.system(cmd);


        # now register the the directional volumes to their closest b0
        non_b0 = [val for val in range(len(bval_total)) if bval_total[val] != 0]

        print("non_b0")
        print(non_b0)
        print("b0_ind")
        print(b0_ind)

        for j in range(len(non_b0)):

            tmp_reg = tmp_dir + 'dti_reg_' + '{0:04d}'.format(non_b0[j]) + '.nii.gz'
            vol_fname = tmp_dir + 'dti_split_' + "{0:04d}".format(non_b0[j]) + '.nii.gz'
            xfm_to_b0 = tmp_dir + 'dti_reg_2b0_' + "{0:04d}".format(non_b0[j]) + '.xfm' # from current vol to closest b0

            tmp_val = [abs(b0_index - non_b0[j]) for b0_index in b0_ind]
            smallest_tmp  = min(tmp_val)
            idx = [val for val in range(len(tmp_val)) if tmp_val[val] == smallest_tmp][0]
            ref_ind = b0_ind[idx];
            ref_fname = tmp_dir + 'dti_split_' + "{0:04d}".format(ref_ind) + '.nii.gz'

            cmd = 'flirt -in ' + vol_fname + ' -ref ' + ref_fname + \
                ' -nosearch -paddingsize 1 -omat ' + xfm_to_b0 + ' -dof 6 '
            os.system(cmd);

            # concat the transformation to closest b0 and from that b0 to ref b0
            if ref_ind == b0_ref:
                xfm_to_ref = tmp_dir + 'dti_reg_' + '{0:04d}'.format(non_b0[j]) + '.xfm'
                cmd = 'cp ' + xfm_to_b0 + ' ' + xfm_to_ref
                os.system(cmd)
            else:
                xfm_b0_to_ref = tmp_dir + 'dti_reg_' + "{0:04d}".format(ref_ind) + '.xfm'  # from closest b0 to ref b0
                xfm_to_ref = tmp_dir + 'dti_reg_' + "{0:04d}".format(non_b0[j]) + '.xfm'
                cmd = 'convert_xfm -omat ' + xfm_to_ref + ' -concat ' + xfm_b0_to_ref + ' ' + xfm_to_b0
                os.system(cmd)

            # now do the transformation to the reference b0
            cmd =  'flirt -in ' + vol_fname + ' -applyxfm -init ' + xfm_to_ref + ' -out ' + tmp_reg + \
                ' -ref ' + ref_fname ## shouldn't this be the first B0/ doesn't actually matter, it's just for the dimensions
            os.system(cmd)

        # do some things that need to be done
        # calls another script
        flirt_str = ""
        bvec_new_total = np.zeros((3,num_vol));
        print(bvec_new_total)
        print("Made it past the first flirt bit...")

        for j in range(num_vol):

            # make string so we can merge all these files together
            tmp_reg = tmp_dir + 'dti_reg_' + "{0:04d}".format(j) + '.nii'
            flirt_str = flirt_str + tmp_reg + ' '

            # import pdb
            # pdb.set_trace()

            # do the bvec correction on each volume
            if j == b0_ref:
                bvec_tmp = bvec_total[:,j]
                bvec_new_fname = tmp_dir + 'bvec_corr_' + str(j) + '.bvec'
                np.savetxt(bvec_new_fname, bvec_tmp)
            else:
                bvec_tmp_fname = tmp_dir + 'bvec_' + str(j) + '.bvec'
                bvec_tmp = bvec_total[:,j]
                np.savetxt(bvec_tmp_fname, bvec_tmp)

                xfm_fname = tmp_dir + 'dti_reg_' + "{0:04d}".format(j) + '.xfm'
                bvec_new_fname = tmp_dir + 'bvec_corr_' + str(j) + '.bvec'
                cmd = correctBvecs + ' ' + bvec_tmp_fname + ' ' + xfm_fname + ' ' + bvec_new_fname
                os.system(cmd)

            bvec_new_total[:,j] = np.loadtxt(bvec_new_fname)


        print("Made it past the bvec correction")
        # save the new bvecs all to one file
        bvec_new_total_fname = process_sub + 'reg_bvec.bvec' # registered, rotated bvecs file name
        np.savetxt(bvec_new_total_fname, bvec_new_total)

        # merge all newly registered volumes
        cmd = 'fslmerge -t ' + dti_ec + ' ' + flirt_str
        os.system(cmd);
        flirt_str = ""

        ## create mean b0 file from all b0s (can use this to make mask)

        b0_str = "";
        for j in range(len(b0_ind)):
            b0_str = b0_str + tmp_dir + 'dti_reg_' + "{0:04d}".format(b0_ind[j]) + '.nii.gz '

        # need to merge these files into one 4d file first
        b0_merge = tmp_dir + 'b0_merge.nii.gz'
        cmd = 'fslmerge -t ' + b0_merge + ' ' + b0_str
        print('Calculating mean b0 and creating mask...')
        os.system(cmd);

        b0_mean = process_sub + 'b0_mean.nii.gz'
        cmd = 'fslmaths ' + b0_merge + ' -Tmean ' + b0_mean
        os.system(cmd)

        # make mask from mean b0
        mask = process_sub + 'b0_mean_mask.nii.gz'
        cmd = '3dAutomask -prefix ' + mask + ' ' + b0_mean
        os.system(cmd);

        print("DONE THIS SUBJECT")

        cmd = 'rm -r ' + tmp_dir
        os.system(cmd)
    except:
        with open('/scratch/nforde/homotopic/bin/fixthese_single.txt', 'a+') as fixthese:
            fixthese.write('{}\n'.format(subjects[i]))
        continue
