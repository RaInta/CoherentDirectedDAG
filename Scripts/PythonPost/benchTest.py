#!/usr/bin/python

#------------------------------------------------------------------------------
#           Name: singleJob.py
#         Author: Ra Inta, 20150205
#  Last Modified: 20150205
#This is a follow-up to the lookThresh.py script; it reads the top_jobs.txt list
# and analyses each candidate job for stats etc. A couple of functions are
# re-used from lookThresh.py, so it's imported here.
#------------------------------------------------------------------------------

from scipy.stats import chi2
import numpy as np
import matplotlib as mpl
mpl.use('Agg')       # This is so we can use matplotlib easily without setting $DISPLAY on remote servers
from matplotlib import pyplot as plt
import xml.etree.ElementTree as ET
import bz2
from math import pow
import os
import string
#from lookThresh import *




#############################################################################################
# 0) Get search_results.txt.$jobId and histogram file
#############################################################################################

# These all come from a loop in the script processSingleJobs.py, which opens the top_jobs.txt file
singleJobId = 22
singleTwoF = 52.0309373
singleFreq = 1404.877544801015

subDir = str( int(singleJobId)/250 )

# Get the results file
singleFreq = []
singleTwoF = []
singleFdot = []
singleFddot = []

for lines in open( os.path.join( os.getcwd(), "jobs", "search", subDir, "search_results.txt." + str(singleJobId) ), 'r').readlines():
   if not lines[0] == '%':
       eachLine = string.split(lines)
       singleFreq.append(  float( eachLine[0]  ) )
       singleTwoF.append(  float( eachLine[6]  ) )
       singleFdot.append(  float( eachLine[3]  ) )
       singleFddot.append( float( eachLine[4]  ) )

# Get the histogram
xHist = []
yHist = []

for lines in open( os.path.join( os.getcwd(), "jobs", "search", subDir, "search_histogram.txt." + str(singleJobId) ), 'r').readlines():
   if not lines[0] == '%':
       eachLine = string.split(lines)
       xHist.append( float( eachLine[0] ) )
       yHist.append( float( eachLine[2] ) )


#############################################################################################

#############################################################################################
# 1) Calculate empirical pdf values
#############################################################################################


## TODO current number of bins is fixed; need to make this more appropriate
#PDF_empir, CDF_binVals = np.histogram(twoF, bins=xHist, density=True)
#CDF_empir = np.cumsum( PDF_empir*np.diff(CDF_binVals) )
#
##############################################################################################
#
##############################################################################################
## 2) Get cleaned results (clean search jobs if not already cleaned)
##############################################################################################
#
#
#figDir=os.path.join(os.getcwd(), 'figures')
#if not os.path.isdir( os.path.join(os.getcwd(), 'cleanedResults', "cleaned_candidate.txt." + str(singleJobId) ) ):
#   print("Warning! No cleaned results file cleaned_candidate.txt." + str(singleJobId) + " found. Attempting to run the cleaning utility" )
#   #if not
#
#
#
##############################################################################################
#
#
##############################################################################################
## 3) Calculate expected 2F_max for this job
##############################################################################################
#
#singleThresh = ""
#singleProb = ""
#
##############################################################################################
#
#
##############################################################################################
## 4) Plot and output everything
##############################################################################################
#
#
#print( "Processing job number "  + singleJobId )
#print( "Loudest 2F: " + str( singleTwoF ) )
#print( "Frequency: " + str( singleFreq ) + "Hz" )
#print( "Expected 2F at (95% C.I.): " + str( singleThresh ) )
#print( "Probability of loudest 2F being in noise: " + str( singleProb ) )
#
#
#
##############################################################################################
## Plot loudest 2F per job vs freq.
##############################################################################################
#
# plt.figure(1)
# #plt.subplot(211)   # Delete the subplot references to keep single plot mode
#
# plt.plot(freq, twoF, "-bo", label="2F distribution")
# plt.plot(freq, [lookThresh for x in range(len(freq))], "-r", label="2F theshold (whole search)")
# plt.plot(freq, [singleThresh for x in range(len(freq))], "-r", label="2F theshold (this job)")
#
# plt.axis([min(freq), max(freq), 0.9*min(twoF), 1.1*max(twoF)])
#
#
# xForPlot = np.linspace(min(freq), max(freq), 5)  # Make 5 marks on abscissa and ordinate
# yForPlot = np.linspace(0.9*min(twoF) , 1.1*max(twoF), 5)
# x2DecPlcs = ['%.2f' % a for a in xForPlot ]
# y2DecPlcs = ['%.2f' % a for a in yForPlot ]
# plt.xticks(xForPlot, x2DecPlcs)
# plt.yticks(yForPlot, y2DecPlcs)
#
# plt.title("$2\mathcal{F}$ distribution, job " + str( singleJobId  ) )
# plt.xlabel("Frequency (Hz)")
# plt.ylabel("$2\mathcal{F}$ ")
#
# legend = plt.legend(loc='best', shadow=True)
# frame = legend.get_frame()   # Some probably overly sophisticated additions to the legend
# frame.set_facecolor('0.90')
#
# #plt.draw()
# plt.savefig( os.path.join(figDir, "twoF_vs_freq.png" ), dpi=None, facecolor='w', edgecolor='w', orientation='portrait', papertype=None, format="png", transparent=
#
#
# plt.figure(2)
# plt.plot(x2F, probVector, "-bo")
# #plt.draw()
# #plt.show()
#
# #############################################################################################
#
#
##------------------------------------------------------------------------------
##           End of singleJob.py
##------------------------------------------------------------------------------
#
