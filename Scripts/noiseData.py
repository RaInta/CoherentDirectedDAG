# -*- coding: utf-8 -*-
#------------------------------------------------------------------------------
#           Name: noiseData.py
#         Author: Ra Inta, 20120531
#  Last Modified: 20120611, R.I.
#    Description: Interpolation of LIGO noise curves, after importing a text
# file output by LALApps functions determining noise floors.
#
#------------------------------------------------------------------------------

from math import pi
from operator import itemgetter
from numpy import *
from scipy import interpolate # Check to see if scipy is installed. Not a default on Linux Debian squeeze
import os, string


# Get frequency limits of noise curve after importing averaged LIGO noise curve
    
    
fNoise = []
hNoise = []

# 1: Read each line in the astro data file, ignoring comment lines ('#')

for xLine in file('H1L1-combined_psd.dat'):
    if not xLine[0] == '#':
        xLine = xLine.split()
        fEachNoise = xLine[0]
        hEachNoise = xLine[1]
        fNoise.append(float(fEachNoise))
        hNoise.append(float(hEachNoise))

fLo = min(fNoise)
fHi = max(fNoise)

bucketIdx, minNoise = min(enumerate(hNoise), key=itemgetter(1))

fBucket = fNoise[bucketIdx]

def fNoiseVector():
    fNoiseVector = list(fNoise)
    return fNoiseVector

def hNoiseVector():
    hNoiseVector = list(hNoise)
    return hNoiseVector

#---------------------------------------------------------------- def fBucket():
    #----------------------------------------------- fBucket = fNoise[bucketIdx]
    #------------------------------------------------------------ return fBucket
    


#------------------------- 2: Interpolate noise curve --------------------------------



# Piecewise power law interpolating function:

#def hNoiseFit(fNoise, hNoise):
#    #hNoiseFitObject = interpolate.interp1d(fNoise, hNoise, kind='linear')
#    #hNoiseFitObject = interpolate.PiecewisePolynomial(fNoise, hNoise, 1)
#    #hNoiseFit = hNoiseFitObject(fNoise)
#    return hNoiseFit

hNoiseFit = []
hNoiseFit = interpolate.interp1d(fNoise, hNoise, kind='linear')
hNoiseFit = hNoiseFit(fNoise)  # Turn interpolate object into vector


#===============================================================================
# def smooth(x,window_len=11,window='hanning'):
#    if x.ndim != 1:
#        raise ValueError, "smooth only accepts 1 dimension arrays."
#    if x.size < window_len:
#        raise ValueError, "Input vector needs to be bigger than window size."
#    if window_len<3:
#        return x
#    
#    if not window in ['flat', 'hanning', 'hamming', 'bartlett', 'blackman']:
#        raise ValueError, "Window is on of 'flat', 'hanning', 'hamming', 'bartlett', 'blackman'"
#    
#    s=numpy.r_[x[window_len-1:0:-1],x,x[-1:-window_len:-1]]
#     #print(len(s))
#     if window == 'flat': #moving average
#         w=numpy.ones(window_len,'d')
#     else:
#         w=eval('numpy.'+window+'(window_len)')
# 
#     y=numpy.convolve(w/w.sum(),s,mode='valid')
#     return y
#===============================================================================




# ------------------------------------------------------------------------------------

# --------- 3: Plot noise curve and fit (optional) -------------------------

plotOption = 0

if plotOption == 1:
    import matplotlib.pyplot as plt
    plt.clf()  # Clear current figure
    plt.semilogy(fNoise, hNoise, 'bo-', label='Noise data')
    plt.semilogy(fNoise, hNoiseFit, 'r-', label='Interpolated fit')
    plt.legend()
    plt.xlabel('Frequency (Hz)')
    plt.ylabel('Strain (\sqrt(Hz)^(-1))')
    plt.savefig('H1L1_noiseCurveInterpolationPlot.png')


# -------------------------------------------------------------------------



#------------------------------ #---------Testing purposes only-----------------
#------------------------------------------------------------------------------ 
#---------------------- print "------------ Output of noise curve -------------"
#----------------------------------- print "Min. frequency: " + str(fLo) + " Hz"
#----------------------------------- print "Max. frequency: " + str(fHi) + " Hz"
#----------------------------- print "Strain in the bucket: " + str(min(hNoise))
#--------------------------- print "Bucket frequency: " + str(fBucket()) + " Hz"
#---------------------------- print "Length of noise data: " + str(size(fNoise))
#----------------------- print "-----------End of noise curve output ----------"
#------------------------------------------------------------------------------ 
#-------------------------------------------- #---------------------------------


# ------------------------------------- End of noiseData.py ---------------------------------       
