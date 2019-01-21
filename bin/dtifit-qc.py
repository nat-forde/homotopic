#!/usr/bin/env python
"""
Run QC -stuff for dtifit outputs.

Usage:
  dtifit-qc.py [options] <dtifitdir>

Arguments:
    <dtifitdir>        Top directory for the output file structure

Options:
  --QCdir <path>           Full path to location of QC outputs (defalt: <outputdir>/QC')
  --tag <tag>              Only QC files with this string in their filename (ex.'DTI60')
  --subject <subid>        Only process the subjects given (good for debugging, default is to do all subs in folder)
  -v,--verbose             Verbose logging
  --debug                  Debug logging in Erin's very verbose style
  -n,--dry-run             Dry run
  --help                   Print help

DETAILS
This creates some QC outputs from of ditfit pipeline stuff.
QC outputs are placed within <outputdir>/QC unless specified otherwise ("--QCdir <path").
Right now QC constist of pictures for every subject.
Pictures are assembled in html pages for quick viewing.

The inspiration for these QC practices come from engigma DTI
http://enigma.ini.usc.edu/wp-content/uploads/DTI_Protocols/ENIGMA_FA_Skel_QC_protocol_USC.pdf

Future plan: add section that checks results for normality and identifies outliers..

Requires datman python enviroment, FSL and imagemagick.

Written by Erin W Dickie, August 25 2015
Adapted for the POND dataset by Natalie Forde, June 2018

This is required before this script will run:
module load use.own
module load datman.module
module load python/2.7.13_sci_01
module load FSL/5.0.10
export PATH=/archive/code/python_2.7.13_datman_01/bin/:$PATH

"""
from docopt import docopt
import pandas as pd
import datman as dm
import datman.utils
import datman.scanid
import os
import tempfile
import shutil
import glob
import sys
import subprocess as proc

arguments       = docopt(__doc__)
dtifitdir       = arguments['<dtifitdir>']
QCdir           = arguments['--QCdir']
TAG             = arguments['--tag']
SUBID           = arguments['--subject']
VERBOSE         = arguments['--verbose']
DEBUG           = arguments['--debug']
DRYRUN          = arguments['--dry-run']

if DEBUG: print arguments
if QCdir == None: QCdir = os.path.join(dtifitdir,'QC')

## check that FSL has been loaded - if not exists
FSLDIR = os.getenv('FSLDIR')
if FSLDIR==None:
    sys.exit("FSLDIR environment variable is undefined. Try again.")

def gif_gridtoline(input_gif,output_gif):
    '''
    uses imagemagick to take a grid from fsl slices and convert to one line (like in slicesdir)
    '''
    dm.utils.run(['convert',input_gif, '-resize', '384x384',input_gif])
    dm.utils.run(['convert', input_gif,\
        '-crop', '100x33%+0+0', os.path.join(tmpdir,'sag.gif')])
    dm.utils.run(['convert', input_gif,\
        '-crop', '100x33%+0+128', os.path.join(tmpdir,'cor.gif')])
    dm.utils.run(['convert', input_gif,\
        '-crop', '100x33%+0+256', os.path.join(tmpdir,'ax.gif')])
    dm.utils.run(['montage', '-mode', 'concatenate', '-tile', '3x1', \
        os.path.join(tmpdir,'sag.gif'),\
        os.path.join(tmpdir,'cor.gif'),\
        os.path.join(tmpdir,'ax.gif'),\
        os.path.join(output_gif)])

def mask_overlay(background_nii,mask_nii, overlay_gif):
    '''
    use slices from fsl to overlay the mask on the background (both nii)
    then make the grid to a line for easier scrolling during QC
    '''
    dm.utils.run(['slices', background_nii, mask_nii, '-o', os.path.join(tmpdir,'BOmasked.gif')])
    gif_gridtoline(os.path.join(tmpdir,'BOmasked.gif'),overlay_gif)

def V1_overlay(background_nii,V1_nii, overlay_gif):
    '''
    use fslsplit to split the V1 image and take pictures of each direction
    use slices from fsl to get the background and V1 picks (both nii)
    recolor the V1 image using imagemagick
    then make the grid to a line for easier scrolling during QC
    '''
    dm.utils.run(['slices',background_nii,'-o',os.path.join(tmpdir,"background.gif")])
    dm.utils.run(['fslmaths',background_nii,'-thr','0.15','-bin',os.path.join(tmpdir,'FAmask.nii.gz')])
    dm.utils.run(['fslsplit', V1_nii, os.path.join(tmpdir,"V1")])
    for axis in ['0000','0001','0002']:
        dm.utils.run(['fslmaths',os.path.join(tmpdir,'V1'+axis+'.nii.gz'), '-abs', \
            '-mul', os.path.join(tmpdir,'FAmask.nii.gz'), os.path.join(tmpdir,'V1'+axis+'abs.nii.gz')])
        dm.utils.run(['slices',os.path.join(tmpdir,'V1'+axis+'abs.nii.gz'),'-o',os.path.join(tmpdir,'V1'+axis+'abs.gif')])
        # docmd(['convert', os.path.join(tmpdir,'V1'+axis+'abs.gif'),\
        #         '-fuzz', '15%', '-transparent', 'black', os.path.join(tmpdir,'V1'+axis+'set.gif')])
    dm.utils.run(['convert', os.path.join(tmpdir,'V10000abs.gif'),\
        os.path.join(tmpdir,'V10001abs.gif'), os.path.join(tmpdir,'V10002abs.gif'),\
        '-set', 'colorspace', 'RGB', '-combine', '-set', 'colorspace', 'sRGB',\
        os.path.join(tmpdir,'dirmap.gif')])
    gif_gridtoline(os.path.join(tmpdir,'dirmap.gif'),overlay_gif)

def SSE_overlay(sse,out,grad):
    '''
    Arguments:
        sse                        Full path to SSE file
        out                        Full path to output
        grad                       Full path to gradient look-up map

    Steps:
    1. Clever/Hacky thresholding so maximum intensity is 2
    2. Generate slices
    3. Use gradient map to color greyscale image
    4. Background filling with 0 fuzziness to prevent leakage
    '''
    slice_out = out.replace('.nii.gz','.gif')
    cmd1 = 'fslmaths {} -sub 2 -mul -1 -thr 0 -mul -1 -add 2 {}'.format(sse,out)
    cmd2 = 'slices {} -o {}'.format(out, slice_out)
    cmd3 = 'convert {} {} -clut {}'.format(slice_out, grad, slice_out)
    cmd4 = 'convert {} -fill black -draw "color 0,0 floodfill" {}'.format(slice_out,slice_out)
    cmdlist = [cmd1, cmd2, cmd3, cmd4]
    outputs = [call(c) for c in cmdlist]
    return


def create_gradient_file(output,color):
    '''
    Arguments:
        output                    Full path to output file
        color                     String argument of Image-Magick 'color:color'
    '''

    cmd = 'convert -size 10x20 gradient:{} {}'.format(color,output)
    call(cmd)
    return

def call(cmd):
    p = proc.Popen(cmd,shell=True,stdin=proc.PIPE, stderr=proc.PIPE)
    std, err = p.communicate()

    if p.returncode:
        print('{} failed with error {}'.format(cmd,err))
    return

def get_sse(sub):
    sse = '{}_dtifit_sse.nii.gz'.format(sub)
    return os.path.join(dtifitdir,sub,sse)

## find the files that match the resutls tag...first using the place it should be from doInd-enigma-dti.py
## find those subjects in input who have not been processed yet and append to checklist
## glob the dtifitdir for FA files to get strings
if SUBID != None:
    allFAmaps = glob.glob(dtifitdir + '/' + SUBID + '/*dtifit_FA*')
else:
    # if no subids given - just glob the whole DTI fit ouput
    allFAmaps = glob.glob(dtifitdir + '/*/*dtifit_FA*')
if DEBUG : print("FAmaps before filtering: {}".format(allFAmaps))

# if filering tag is given...filter for it
if TAG != None:
    allFAmaps = [ v for v in allFAmaps if TAG in v ]
if DEBUG : print("FAmaps after filtering: {}".format(allFAmaps))
allFAmaps = [ v for v in allFAmaps if "PHA" not in v ] ## remove the phantoms from the list

#mkdir a tmpdir for the
#tmpdirbase = tempfile.mkdtemp()
tmpdirbase = os.path.join(QCdir,'tmp')
dm.utils.makedirs(tmpdirbase)

# make the output directories
QC_bet_dir = os.path.join(QCdir,'BET')
QC_V1_dir = os.path.join(QCdir, 'directions')
QC_FM_dir = os.path.join(QCdir, 'FM')
QC_Mag_dir = os.path.join(QCdir, 'Mag')
QC_SSE_dir = os.path.join(QCdir, 'sse')
dm.utils.makedirs(QC_bet_dir)
dm.utils.makedirs(QC_V1_dir)
dm.utils.makedirs(QC_FM_dir)
dm.utils.makedirs(QC_Mag_dir)
dm.utils.makedirs(QC_SSE_dir)

grad_out = os.path.join(tmpdirbase,'ramp.gif')
create_gradient_file(grad_out,'red-yellow')

maskpics = []
V1pics = []
FMpics = []
Magpics = []
Respics = []
for FAmap in allFAmaps:
    ## manipulate the full path to the FA map to get the other stuff
    subid = os.path.basename(os.path.dirname(FAmap))
    tmpdir = os.path.join(tmpdirbase,subid)
    dm.utils.makedirs(tmpdir)
    basename = os.path.basename(FAmap).replace('dtifit_FA.nii.gz','')
    pathbase = FAmap.replace('dtifit_FA.nii.gz','')
    pathdir = os.path.dirname(pathbase)
    print(pathdir)
    maskpic = os.path.join(QC_bet_dir,basename + 'b0_bet_mask.gif')
    maskpics.append(maskpic)
    mask_overlay(os.path.join(pathdir,'b0.nii.gz'), os.path.join(pathdir,'nodif_brain_mask.nii.gz'), maskpic)

    V1pic = os.path.join(QC_V1_dir,basename + 'dtifit_V1.gif')
    V1pics.append(V1pic)
    V1_overlay(FAmap,pathbase + 'dtifit_V1.nii.gz', V1pic)

    FMpic = os.path.join(QC_FM_dir,basename + 'FM.gif')
    FMpics.append(FMpic)
    mask_overlay(os.path.join(pathdir,'b0.nii.gz'), os.path.join(pathdir,'all/fieldmap_diff_bin.nii.gz'), FMpic)

    Magpic = os.path.join(QC_Mag_dir,basename + 'Mag.gif')
    Magpics.append(Magpic)
    mask_overlay(os.path.join(pathdir,'b0.nii.gz'), os.path.join(pathdir,'all/Mag_bet_diff_bin.nii.gz'), Magpic)

    Restmp = os.path.join(tmpdir,'resmap.gif')
    Respic = os.path.join(QC_SSE_dir,basename + 'Res.gif')
    Respics.append(Respic)
    # SSE_overlay(pathbase + 'dtifit_sse.nii.gz', Respic)

    sse = get_sse(subid)
    # sout = os.path.join(output, '{}.nii.gz'.format(subject))
    SSE_overlay(sse,Restmp,grad_out)
    # SSE_overlay(sse,sout,grad_out) # jerry orig
    gif_gridtoline(Restmp,Respic)

## write an html page that shows all the BET mask pics
qchtml = open(os.path.join(QCdir,'qc_BET.html'),'w')
qchtml.write('<HTML><TITLE>DTIFIT BET QC page</TITLE>')
qchtml.write('<BODY BGCOLOR=#333333>\n')
qchtml.write('<h1><font color="white">DTIFIT BET QC page</font></h1>')
for pic in maskpics:
    relpath = os.path.relpath(pic,QCdir)
    qchtml.write('<a href="'+ relpath + '" style="color: #99CCFF" >')
    qchtml.write('<img src="' + relpath + '" "WIDTH=800" > ')
    qchtml.write(relpath + '</a><br>\n')
qchtml.write('</BODY></HTML>\n')
qchtml.close() # you can omit in most cases as the destructor will call it

## write an html page that shows all the V1 pics
qchtml = open(os.path.join(QCdir,'qc_directions.html'),'w')
qchtml.write('<HTML><TITLE>DTIFIT directions QC page</TITLE>')
qchtml.write('<BODY BGCOLOR=#333333>\n')
qchtml.write('<h1><font color="white">DTIFIT directions QC page</font></h1>')
for pic in V1pics:
    relpath = os.path.relpath(pic,QCdir)
    qchtml.write('<a href="'+ relpath + '" style="color: #99CCFF" >')
    qchtml.write('<img src="' + relpath + '" "WIDTH=800" > ')
    qchtml.write(relpath + '</a><br>\n')
qchtml.write('</BODY></HTML>\n')
qchtml.close() # you can omit in most cases as the destructor will call it

# write an html page that shows all the Fieldmap pics
qchtml = open(os.path.join(QCdir,'qc_fieldmap.html'),'w')
qchtml.write('<HTML><TITLE>DTIFIT fieldmap QC page</TITLE>')
qchtml.write('<BODY BGCOLOR=#333333>\n')
qchtml.write('<h1><font color="white">DTIFIT fieldmap QC page</font></h1>')
for pic in FMpics:
    relpath = os.path.relpath(pic,QCdir)
    qchtml.write('<a href="'+ relpath + '" style="color: #99CCFF" >')
    qchtml.write('<img src="' + relpath + '" "WIDTH=800" > ')
    qchtml.write(relpath + '</a><br>\n')
qchtml.write('</BODY></HTML>\n')
qchtml.close() # you can omit in most cases as the destructor will call it

## write an html page that shows all the Mag pics
qchtml = open(os.path.join(QCdir,'qc_mag.html'),'w')
qchtml.write('<HTML><TITLE>DTIFIT magnitude QC page</TITLE>')
qchtml.write('<BODY BGCOLOR=#333333>\n')
qchtml.write('<h1><font color="white">DTIFIT magnitude QC page</font></h1>')
for pic in Magpics:
    relpath = os.path.relpath(pic,QCdir)
    qchtml.write('<a href="'+ relpath + '" style="color: #99CCFF" >')
    qchtml.write('<img src="' + relpath + '" "WIDTH=800" > ')
    qchtml.write(relpath + '</a><br>\n')
qchtml.write('</BODY></HTML>\n')
qchtml.close() # you can omit in most cases as the destructor will call it

## write an html page that shows all the Res pics
qchtml = open(os.path.join(QCdir,'qc_res.html'),'w')
qchtml.write('<HTML><TITLE>DTIFIT residual QC page</TITLE>')
qchtml.write('<BODY BGCOLOR=#333333>\n')
qchtml.write('<h1><font color="white">DTIFIT residual QC page</font></h1>')
for pic in Respics:
    relpath = os.path.relpath(pic,QCdir)
    qchtml.write('<a href="'+ relpath + '" style="color: #99CCFF" >')
    qchtml.write('<img src="' + relpath + '" "WIDTH=800" > ')
    qchtml.write(relpath + '</a><br>\n')
qchtml.write('</BODY></HTML>\n')
qchtml.close() # you can omit in most cases as the destructor will call it

#get rid of the tmpdir
shutil.rmtree(tmpdirbase)
