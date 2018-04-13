#!/usr/bin/python

#------------------------------------------------------------------------------
#           Name: lookThresh.py
#         Author: Ra Inta, 20150128
#  Last Modified: 20150218
#This is to calculate the 'further look' threshold for the maximum 2F value from a directed CW gravitational wave search.
# It also creates a top_jobs.txt list of candidates and generates figures in a newly created 'figures' folder.
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



# Kludge approach: specify support for 2F
# TODO come up with a way to do this without a priori support
min2Fthresh = 30
max2Fthresh = 400

############################################################
#1) Take in search results: total number of templates, number of search bands, loudest 2Fs of non-vetoed templates
############################################################

input_file = bz2.BZ2File('search_bands.xml.bz2', 'rb')
tree = ET.parse( input_file )
root = tree.getroot()

twoF = []
freq = []
jobId = []
num_templates = []

# Walk through the XML tree for 2F and f0; don't pick up the vetoed bands. Have
# to keep jobId label to produce topJobs list.
#for jobNumber in root.iter('job'):
#    nodeInfo = root[int(jobNumber.text)].find('loudest_nonvetoed_template')
#    if nodeInfo is not None:
#        twoF.append( float( nodeInfo.find('twoF').text ) )
#        freq.append( float( nodeInfo.find('freq').text ) )
#        jobId.append( jobNumber.text )

# Get number of templates in each band
for nTempl in root.iter('num_templates'):
   num_templates.append( float( nTempl.text ) )



############################################################
#2) Make histograms and CDFs of max(2F) values
############################################################

# TODO current number of bins is fixed; need to make this more appropriate
PDF_empir, CDF_binVals = np.histogram(twoF, bins=100, density=True)
CDF_empir = np.cumsum( PDF_empir*np.diff(CDF_binVals) )


############################################################
#3) find stats (mean, variance, max 2F) of number of templates
############################################################

Nmean = np.mean( num_templates )
stdTempl = np.std( num_templates )
#max2F = np.max( twoF  )
#maxIdx = np.where( twoF == np.max(twoF) )[0][0]
#max2F = twoF[ maxIdx ]
#max2FFreq = freq[ maxIdx ]
Ntot = np.sum( num_templates )

############################################################
#4) Find effective number of templates, Neff, by finding where the K-S distance is a minimum, by calculating theoretical CDF(Chi2(N,4)) and taking difference to empirical distribution
############################################################

def CDF_trial(N, x):
    """Calculated theoretical expectation for CDF"""
    return np.array( np.power( chi2.cdf( np.array(x) , 4 ) , N ) )

def ksDist(N, CDF_empir, CDF_binVals):
    """Work out the Kolmogorov-Smirnoff distance between empirical cdf and theoretical one.
    Requires an array of CFD bin values, CDF_binVals"""
    return np.max( np.abs( CDF_empir - CDF_trial(N, CDF_binVals[1:]) ) )

# Make 200 guesses along the sensible domain of N
# TODO use optimisation tools/package or Newton-Raphson instead
Nvector = np.linspace(0.5*Nmean, Nmean, num=1200)

ksPlot = [ ksDist(NIdx, CDF_empir, CDF_binVals) for NIdx in Nvector]
Neff = Nvector[np.where( ksPlot == np.min(ksPlot) )[0][0] ]
#ksMin = min([ ksDist(NIdx, CDF_empir, CDF_binVals) for NIdx in np.linspace(0, Ntot, num=50) ] )


############################################################
#5) Find further look threshold by evaluating where [ CDF(Chi2(Neff,4))== \alpha ] for confidence level \alpha
############################################################

# Simple theoretical probability the overall max2F came from Gaussian noise
P2Fmax = 1 - chi2.cdf(max2F, 4)

def prob(N, max2F):
   """Works out the probability given a number of templates and a maximum twoF"""
   littleP = 1 - chi2.cdf(max2F, 4)
   return N * littleP * pow(chi2.cdf(max2F, 4) , N )



Pval = prob(Neff*Ntot/Nmean, max2F)

############################################################
# Find x, where p(x) is first expected to be > 95%
############################################################


def getLookThresh(Ntot, min2Fthresh, max2Fthresh ):
    """getLookThresh produces a fine Chi2 distribution to evaluate the further look threshold.
    TODO get rid of explicit domain support for 2F range."""
    x2F = np.arange(min2Fthresh, max2Fthresh, 0.1)
    probVector = [prob(Ntot, x) for x in x2F]
    # only evaluate distribution after maximum
    # have to worry about numpy's float64 return values... (and array indexing)
    x2FmaxIdx = np.where( probVector == max(probVector) )
    return x2F[ np.min( np.where( probVector[x2FmaxIdx[0][0]:] < np.float64(0.05) ) ) + x2FmaxIdx ][0][0]

#x2F = np.arange(min2Fthresh, max2Fthresh, 0.1)
#probVector = [prob(Ntot, x) for x in x2F]
#
## only evaluate distribution after maximum
## have to worry about numpy's float64 return values... (and array indexing)
#x2FmaxIdx = np.where( probVector == max(probVector) )
#lookThresh = x2F[ np.min( np.where( probVector[x2FmaxIdx[0][0]:] < np.float64(0.05) ) ) + x2FmaxIdx ][0][0]


lookThresh = getLookThresh(Ntot, min2Fthresh, max2Fthresh)

############################################################

############################################################
# 6) Create top_jobs.txt file
############################################################


#topJobs = open('top_jobs.txt','w')
#
#topJobsIdx = np.where( twoF >= lookThresh  )
#topJobs.write("% Look threshold: " + str(lookThresh) + "\n")
#topJobs.write("% jobNumber twoF_max start_freq \n")
#[ topJobs.write(str(jobId[Idx]) + " " + str(twoF[Idx]) + " " + str(freq[Idx]) + "\n") for Idx in topJobsIdx[0] ]
#topJobs.write("%DONE")
#topJobs.close()
#


############################################################

############################################################
# 7) Display and graph everything
############################################################

#print("Number of search jobs: " + str( len( twoF ) ) )
print("Total number of templates: " + str( Ntot ) )
print("Mean templates per search band: " + str(Nmean) )
print("Std dev.: " + str(stdTempl) )
print("Effective N: " + str(Neff) + " \nEffective ratio: " + str(Neff/Nmean) )
print("Maximum 2F value overall: 2F_max=" + str( max2F ))
print("Probability of this in Gaussian noise: P(2F_max)=" + str( Pval  ) )
print("Further look theshold: " + str( lookThresh ) )


############################################
#  Plot/save results if prompted   #########
############################################
# Note that the use of the mpl.use('Agg') in the header means that we don't have to directly
# interface with the matplotlib API in a more detailed way,
# Otherwise, the following requires the $DISPLAY variable to be set. This is
# *not* a default setting when logging into remote machines!!!
# You can set this using e.g. X11 tunnelling (i.e. ssh -Y user@hostname )
###################################################################################

figDir=os.path.join(os.getcwd(), 'figures')
if not os.path.isdir(figDir):
    os.mkdir(figDir)


#############################################################################################
# Plot loudest 2F per job vs freq.
#############################################################################################

plt.figure(1)
plt.plot(freq, twoF, "-bo", label="2F distribution")
plt.plot(freq, [lookThresh for x in range(len(freq))], "-r", label="2F theshold (95% C.I.)")

plt.axis([min(freq), max(freq), 0.9*min(twoF), 1.1*np.max([lookThresh, max(twoF)] ) ])

xForPlot = np.linspace(min(freq), max(freq), 5)  # Make 5 marks on abscissa and ordinate
yForPlot = np.linspace(0.9*min(twoF) , 1.1*max(twoF), 5)
x2DecPlcs = ['%.2f' % a for a in xForPlot ]
y2DecPlcs = ['%.2f' % a for a in yForPlot ]
plt.xticks(xForPlot, x2DecPlcs)
plt.yticks(yForPlot, y2DecPlcs)

plt.title("$2\mathcal{F}$ distribution, whole search")
plt.xlabel("Frequency (Hz)")
plt.ylabel("Maximum $2\mathcal{F}$ per job")

legend = plt.legend(loc='best', shadow=True)
frame = legend.get_frame()   # Some probably overly sophisticated additions to the legend
frame.set_facecolor('0.90')

plt.savefig( os.path.join(figDir, "twoF_vs_freq.png" ), dpi=None, facecolor='w', edgecolor='w', orientation='portrait', papertype=None, format="png", transparent=False, bbox_inches=None, pad_inches=0.5, frameon=None)


#plt.figure(2)
#plt.plot(x2F, probVector, "-bo")
##plt.draw()
##plt.show()
#plt.savefig( os.path.join(figDir, "Prob_distribution.png"), dpi=None, facecolor='w', edgecolor='w', orientation='portrait', papertype=None, format="png", transparent=False, bbox_inches=None, pad_inches=0.5, frameon=None)



############################################################################################
# Plot the histograms and CDF
############################################################################################

plt.figure(3)
plt.subplot(311)
plt.plot(CDF_binVals[1:],PDF_empir, "-ko")
plt.title("Histogram and CDFs of loudest $2\mathcal{F}$ per band")
plt.ylabel("Histogram")

plt.subplot(312)
plt.plot(CDF_binVals[1:],CDF_empir, "-ko", label="Empirical")
plt.plot(CDF_binVals[1:], [ CDF_trial(Nmean,x) for x in CDF_binVals[1:] ], "-ro", label="Expected")
legend = plt.legend(loc='lower right', shadow=True)
frame = legend.get_frame()   # Some probably overly sophisticated additions to the legend
frame.set_facecolor('0.90')
#plt.title("Empirical and expected CDFs")
plt.ylabel("Cumulative")

plt.subplot(313)
plt.plot(CDF_binVals[1:],np.abs( CDF_empir - [CDF_trial(Nmean,x) for x in CDF_binVals[1:]]), "-ko")
plt.xlabel("Maximum $2\mathcal{F}$ per search band")
#plt.title("Difference in CDFs")
plt.ylabel("|Difference|")

#plt.draw()
#plt.show()
plt.savefig( os.path.join(figDir, "PDF_CDF.png"), dpi=None, facecolor='w', edgecolor='w', orientation='portrait', papertype=None,
            format="png", transparent=False, bbox_inches=None, pad_inches=0.5, frameon=None)


############################################################################################



############################################################################################
# Plot the minimum K-S distance
############################################################################################

plt.figure(10)
plt.plot(Nvector, ksPlot,'-ko')

plt.title("Determination of effective number of independent templates")
plt.xlabel("Number of templates")
plt.ylabel("Kolmogorov-Smirnoff distance")

#plt.draw()
#plt.show()
plt.savefig( os.path.join(figDir, "Neff_graph.png"), dpi=None, facecolor='w', edgecolor='w', orientation='portrait', papertype=None,
            format="png", transparent=False, bbox_inches=None, pad_inches=0.5, frameon=None)
############################################################################################




#############################################################################################

#exit(0)


############################################################
#  End of lookThresh.py
############################################################
