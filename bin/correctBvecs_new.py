#!/usr/bin/python
#
# Takes a bvecs file (as per FSL) columns of diffusion encoding vectors
# and rotates them to match the transformations that occured in eddy currect correction
# Based on correctBvecs.pl, ported to Python (Drew Morris, 2009)
#
# AUTHOR: Gabrielle Singh Cadieux
# CREATED: August 21, 2012
# NOTES:
#
###############################################################################################

from __future__ import with_statement
import sys, os, subprocess, re, tempfile

def usage():
  print '%s bvecsIN transformations bvecsOUT [aff12format]' % os.path.split(sys.argv[0])[1]

if len(sys.argv) < 4:
  usage()
  sys.exit()

#get command line arguments
sBvecsFile = sys.argv[1]
sTransFile = sys.argv[2]
sOutFile = sys.argv[3]
if len(sys.argv) > 4:
  bAFNIformat = sys.argv[4]
else:
  bAFNIformat = ''

#check whether afni format is specified
if str.lower(bAFNIformat) in ('yes','1','afni','y'):
  bAFNIformat = 1
  print 'reading afni format'
else:
  bAFNIformat = 0

sCommand = None


base_tmp_dir = os.path.dirname(sBvecsFile)
tmp_dir = tempfile.mkdtemp(dir=base_tmp_dir)

#create temporary copies of input files
process = subprocess.Popen('cp {} {}'.format(sTransFile, os.path.join(tmp_dir, 'temp_xfm.ecclog' )), shell = True, stdout = subprocess.PIPE).wait()
sTransFile = os.path.join(tmp_dir, 'temp_xfm.ecclog' )
process = subprocess.Popen('cp {} {}'.format(sBvecsFile, os.path.join( tmp_dir, 'temp_bvecs')), shell = True, stdout = subprocess.PIPE).wait()
sBvecsFile = os.path.join( tmp_dir, 'temp_bvecs')

sBvecsTFile = sBvecsFile + '.T'
i = -1
while os.path.isfile(sBvecsTFile):
  i += 1
  sBvecsTFile = sBvecsFile + '.T' + str(i)

#count number of lines/vectors in bvecs file
process = subprocess.Popen('1dtranspose %s > %s' % (sBvecsFile, sBvecsTFile), shell = True, stdout = subprocess.PIPE).wait()
with open(sBvecsTFile, 'r') as f:
  lineCount = 0
  for line in f:
    lineCount += 1
print 'there are %d vectors in %s' % (lineCount, sBvecsFile)
if lineCount == 0:
  print '%s is not numeric' % sBvecsFile
  sys.exit()

#check whether xfm file exists
if not os.path.isfile(sTransFile):
  print 'File %s doesn\'t exist' % sTransFile
  sys.exit()

#create temporary files
pid = str(os.getpid())

sTempMatFile = os.path.join(tmp_dir, 'TEMP{}.mat.ID'.format(pid))
i = -1
while os.path.isfile(sTempMatFile):
  i += 1
  sTempMatFile = os.path.join(tmp_dir, 'TEMP{}{}.mat.ID'.format(pid, str(i)))

process = subprocess.Popen('touch %s' % sTempMatFile, shell = True, stdout = subprocess.PIPE).wait()

sTempVecFile = os.path.join(tmp_dir, 'TEMP{}.vec.ID'.format(pid))

i = -1
while os.path.isfile(sTempVecFile):
  i += 1
  sTempVecFile = os.path.join(tmp_dir, 'TEMP{}{}.vec.ID'.format(pid, str(i)))

process = subprocess.Popen('touch %s' % sTempVecFile, shell = True, stdout = subprocess.PIPE).wait()

sTempEyeXfmFile = os.path.join(tmp_dir, 'TEMP{}.eye.xfm'.format(pid))
i = -1
while os.path.isfile(sTempEyeXfmFile):
  i += 1
  sTempEyeXfmFile = os.path.join(tmp_dir, 'TEMP{}{}.eye.xfm'.format(pid, str(i)))

process = subprocess.Popen('touch %s' % sTempEyeXfmFile, shell = True, stdout = subprocess.PIPE).wait()

#clobbernot(re.search('Final', sLine) or re.search('processing', sLine)):
if os.path.isfile(sOutFile):
  os.remove(sOutFile)

#create new linear xfm files
process = subprocess.Popen('param2xfm -clobber %s' % sTempEyeXfmFile, shell = True, stdout = subprocess.PIPE).wait()
process = subprocess.Popen('head -n 6 %s > %s.hdr' % (sTempEyeXfmFile, sTempEyeXfmFile), shell = True, stdout = subprocess.PIPE).wait()

#open xfm file for reading
with open(sTransFile, 'r') as TRANS:
  iTransCount = 0
  sLine = None

    #iterate over lines in xfm file
  for line in TRANS:
    sLine = line.rstrip()

    #check whether xfm file is in AFNI format
    if bAFNIformat:
      print 'trans',
      iTransCount += 1
      process = subprocess.Popen('cp %s.hdr %s' % (sTempEyeXfmFile, sTempMatFile), shell = True, stdout = subprocess.PIPE).wait()

      #write matrix to temporary file
      with open(sTempMatFile, 'a') as TEMPMAT:
        print 'transform # %d' % iTransCount

        match = re.compile('(\S+\s+)(\S+\s+)(\S+\s+)(\S+\s+)(\S+\s+)(\S+\s+)(\S+\s+)(\S+\s+)(\S+\s+)(\S+\s+)(\S+\s+)(\S+)').search(sLine)
        if match:
          TEMPMAT.write(match.group(1) + match.group(2) + match.group(3) + match.group(4) + '\n' + match.group(5) + match.group(6) + \
            match.group(7) + match.group(8) + '\n' + match.group(9) + match.group(10) + match.group(11) + match.group(12))

    #search for matrix delimiters
    #elif re.compile('^\s*$').search(sLine) or not(re.compile('Final\sresult').search(sLine) or re.compile('processing').search(sLine)): #match empty lines separating matrices
    #elif re.compile('^Final\sresult').search(sLine): #match 'Final result' separating matrices
    elif not(re.search('Final', sLine) or re.search('processing', sLine) or not(sLine)):
      iTransCount += 1
      process = subprocess.Popen('cp %s.hdr %s' % (sTempEyeXfmFile, sTempMatFile), shell = True, stdout = subprocess.PIPE).wait()

      #write matrix to temporary file
      with open(sTempMatFile, 'a') as TEMPMAT:
        print 'transform # %d' % iTransCount
        for i in range(1, 4):
          if i == 3:
            TEMPMAT.write(sLine + ';')
          else:
            TEMPMAT.write(sLine + '\n')
          print sLine,
          sLine = TRANS.next().rstrip()

    else:
       continue

    sCommand = 'xfm2param %s | grep rotation' % sTempMatFile
    print sCommand
    process = subprocess.Popen(sCommand, shell = True, stdout = subprocess.PIPE)
    output, errors = process.communicate()
    match = re.compile('(\-?\d+\.\d+)\s+(\-?\d+\.\d+)\s+(\-?\d+\.\d+)').search(output)
    if match:
      fr1 = match.group(1)
      fr2 = match.group(2)
      fr3 = match.group(3)
      sCommand = 'param2xfm -clobber -rotations %s %s %s %s' % (fr1, fr2, fr3, sTempMatFile) #only Rotations 3x4
      print sCommand

      sNewTempFile = sTempMatFile + '2'
      j = -1
      while os.path.isfile(sNewTempFile):
        j += 1
        sNewTempFile = sTempMatFile + str(j)

      process = subprocess.Popen('tail -n 3 %s > %s' % (sTempMatFile, sNewTempFile), shell = True, stdout = subprocess.PIPE).wait() #get rid of header stuff
      process = subprocess.Popen('1dtranspose %s > %s' % (sNewTempFile, sTempMatFile), shell = True, stdout = subprocess.PIPE).wait()
      process = subprocess.Popen('1dtranspose %s > %s' % (sTempMatFile, sNewTempFile), shell = True, stdout = subprocess.PIPE).wait() #get rid of semi-colon - sNewTmpMFile contains only rotations 3x4
      process = subprocess.Popen('1dcat %s\'[0..2]\' > %s' % (sNewTempFile, sTempMatFile), shell = True, stdout = subprocess.PIPE).wait() #stempmat contains 3x3
      print 'rotate only transform:'
      process = subprocess.Popen('cat %s' % sTempMatFile, shell = True, stdout = subprocess.PIPE)
      output, errors = process.communicate()
      print output
      process = subprocess.Popen('1dcat %s\'[%d]\' > %s' % (sBvecsFile, (iTransCount - 1), sTempVecFile), shell = True, stdout = subprocess.PIPE).wait()
      process = subprocess.Popen('cp %s %s' % (sTempVecFile, sNewTempFile), shell = True, stdout = subprocess.PIPE).wait()

      print 'old vector: ',
      process = subprocess.Popen('1dtranspose %s' % sTempVecFile, shell = True, stdout = subprocess.PIPE)
      output, errors = process.communicate()
      print output
      os.remove(sTempVecFile)

      process = subprocess.Popen('1dmatcalc \'&read(%s) &read(%s) * &write(%s)\'' % (sTempMatFile, sNewTempFile, \
        sTempVecFile), shell = True, stdout = subprocess.PIPE).wait()

      print 'new vector: ',
      process = subprocess.Popen('1dtranspose %s' % sTempVecFile, shell = True, stdout = subprocess.PIPE)
      output, errors = process.communicate()
      print output
      if os.path.isfile(sOutFile):
        process = subprocess.Popen('cp %s %s' % (sOutFile, sNewTempFile), shell = True, stdout = subprocess.PIPE).wait()
        process = subprocess.Popen('1dcat %s %s > %s' % (sNewTempFile, sTempVecFile, sOutFile), shell = True, stdout = subprocess.PIPE).wait()
      else:
        process = subprocess.Popen('1dcat %s > %s' % (sTempVecFile, sOutFile), shell = True, stdout = subprocess.PIPE).wait()
      os.remove(sNewTempFile)
      os.remove(sTempMatFile)
      os.remove(sTempVecFile)

    else:
      print 'couldn\'t find rotations on transformation %d' % iTransCount

      os.remove(sTempMatFile)
      continue

  print 'transform done'
  print iTransCount
if iTransCount != lineCount:
  print 'Warning: The number of columns in %s did not match the number of transformations in %s.' % (sBvecsFile, sTransFile)
print sBvecsTFile
print sTempEyeXfmFile
print sBvecsFile
print sTransFile
os.remove(sBvecsTFile)
os.remove(sTempEyeXfmFile)
os.remove(sTempEyeXfmFile + '.hdr')
os.remove(sBvecsFile)
os.remove(sTransFile)
