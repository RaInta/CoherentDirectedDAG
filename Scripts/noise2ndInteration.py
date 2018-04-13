# -*- coding: utf-8 -*-
#------------------------------------------------------------------------------
#           Name: noise2ndIteration.py
#         Author: Ra Inta, 20120619
#  Last Modified: 20120619, R.I.
#    Description: This is a finer iteration of the noise curve based on the PSD of the actual SFTs used 
# in the search for each target. 
#
#------------------------------------------------------------------------------

from math import pi
from operator import itemgetter
from numpy import *
from scipy import interpolate # Check to see if scipy is installed. Not a default on Linux Debian squeeze
import os, string
from noiseData import *
from upperLimitCalcs import *
from timeBandSolver import *
from readAstroDat import *

# Get the noise file by running “lalapps_ComputePSD --outputPSD fullpsd.dat --PSDmthopSFTs 4 --PSDmthopIFOs 4 --
# PSDmthopBins 4 --binSizeHz 1 --fStart 40 --fBand 1995 --blocksRngMed 50 --inputData global/sfts/*” in each search
#--------- directory, then gsiscp it to my machine to run this notebook section:

# Old, S6 version:
#os.system('lalapps_ComputePSD --outputPSD fullpsd.dat --PSDmthopSFTs 4 --PSDmthopIFOs 4 --PSDmthopBins 4 --binSizeHz 1 --fStart 40 --fBand 1995 --blocksRngMed 50 --inputData global/sfts/*')

# New, O1 version:
#os.system('lalapps_ComputePSD --outputPSD fullpsd.dat --PSDmthopSFTs 4 --PSDmthopIFOs 4 --PSDmthopBins 4 --binSizeHz 1 --fStart 30 --fBand 1969 --blocksRngMed 50 --inputData global/sfts/*')
# Contraband O1 version:
os.system('lalapps_ComputePSD --outputPSD fullpsd.dat --PSDmthopSFTs 4 --PSDmthopIFOs 4 --PSDmthopBins 4 --binSizeHz 1 --fStart 15 --fBand 1984 --blocksRngMed 50 --inputData global/sfts/*')


fNoise = []
hNoise = []
loghNoise = []

for xLine in file('fullpsd.dat'):
    if not xLine[0] == '#':
        xLine = xLine.split()
        fEachNoise = xLine[0]
        hEachNoise = xLine[1]
        fNoise.append(float(fEachNoise))
        hNoise.append(float(hEachNoise))
        loghNoise.append( math.log( float(hEachNoise), 10 ) )


bucketFreq = fBucket(fNoise, hNoise)

#------------------------------------------------- TSpan = read optimal stretch to get TSpan

each_h095 = []

for targIdx in range(len(GCoOrds)):
    eachTargName = TargNames[targIdx]
    targDirName = eachTargName
    eachDkpc = float(DISTkpc[targIdx])
    eachTAUkyr =  float(TAUkyr[targIdx])
    eachTSpan = timeBand(eachDkpc, eachTAUkyr, costTarget, hNoise, fBucket, theta)[2]
    each_h095(eachTSpan, hNoiseFit, theta)


