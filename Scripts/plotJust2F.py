#!/usr/bin/python
#
###########################################
#
# File: plotJust2F.py
# Author: Ra Inta
# Description:
# Created: May 02, 2017
# Last Modified: May 02, 2017
#
###########################################

import pandas as pd
import numpy as np
import matplotlib as mpl
mpl.use('Agg')       # This is so we can use matplotlib easily without setting $DISPLAY on remote servers
import matplotlib.pyplot as plt
from sys import argv
from scipy import stats
import os

# Why can't we just have a decent default for our matplotlib font?
plt.rcParams["font.family"] = "serif"

# Input job number as integer
#try:
#    if type(argv[1]) is int:
#        jobId = argv[1]
#        if not argv[1]:
#            raise ValueError('empty string')
#except ValueError as e:
#    print(e)

targName = argv[1]
jobId = argv[2]

# Number of jobs per directory hard-coded here for the moment.
JOBS_PER_DIRECTORY = 250

#searchFileName = os.path.join("jobs", "search", str( jobId/JOBS_PER_DIRECTORY ) ,"cleaned_candidate.txt."+str(jobId) )
# FIXME For the moment, we'll look in the cleanedCandidate directory
#searchFileName = os.path.join("jobs", "search", str( jobId/JOBS_PER_DIRECTORY ) ,"cleaned_candidate.txt."+str(jobId) )
searchFileName = os.path.join("jobs", "search", str( int(jobId)/JOBS_PER_DIRECTORY ) ,"search_results.txt." + str(jobId) )
#searchFileName = os.path.join( "data", "search_results", str(targName), "cleanedResults", "cleaned_candidate.txt."+str(jobId) )
#searchFileName = os.path.join( str(targName), "jobs","search","0", "search_results.txt."+str(jobId) )
#threshFileName = os.path.join(os.getcwd(), str(targName), "twoFthresh.txt")
threshFileName = os.path.join(os.getcwd(), "twoFthresh.txt")


colIdx = ["freq", "alpha", "delta", "f1dot", "f2dot", "f3dot", "twoF", "log10BSGL", "twoFH1", "twoFL1" ]
test_data = pd.read_csv(searchFileName, sep=" ", comment='%', names=colIdx )

# Bin the histogram with widths of 0.1
#binVect=np.arange(min(test_data["twoF"]),max(test_data["twoF"]),0.1)
# For the moment, we'll constrain the domain to 2F = (~33, 200)
min_2F = 33.3768  # Minimum 2F, set for 1 in a million in Gaussian noise (for given number of templates)
max_2F = 200  # Maximum 2F, set for where analytic model becomes unstable (for given number of templates)

binVect = np.arange(min_2F, max_2F, 0.1)
twoFHist = np.histogram(test_data["twoF"], binVect)
center = (binVect[:-1] + binVect[1:]) / 2

# create null distribution (Chi^2 with 4d.f.)
nullDist = stats.chi2.pdf(binVect, 4, loc=0, scale=1)
# Normalise by the first entry in the empirical distribution
nullDistNorml = [x*(twoFHist[0][0]/nullDist[0]) for x in nullDist]

## Create histogram tail file of cleaned results:
np.savetxt("results/vetoed_line_histogram_" + str(targName) + "_" + str(jobId) + ".txt", zip(twoFHist[1], twoFHist[0]))
#
#
plt.figure(2)

#plt.figure(3)
plt.subplot(211)   # Delete the subplot references to keep single plot mode
plt.plot(test_data["freq"], test_data["twoF"], '.k', alpha=0.5)
# Plot the ciritical threshold if it exists
if os.path.isfile( threshFileName):
    with open(threshFileName,'r') as threshFile:
        twoFthresh = float(threshFile.readlines()[0])
        plt.plot(test_data["freq"], twoFthresh*np.ones(np.size(test_data["freq"])), ':r', alpha=0.5)
plt.title(r'$2\mathcal{F}$ vs frequency for target ' + str(targName) + " (Job: " + str(jobId) + ")" )
plt.xlabel("Frequency (Hz)", fontsize=16)
plt.ylabel(r'$2\mathcal{F}$', fontsize=16)
#plt.savefig("figures/cleaned_candidate_2F_" + str(targName) + "_" + str(jobId) + ".png", dpi=None, facecolor='w', edgecolor='w', orientation='portrait', papertype=None, format="png", transparent=False, bbox_inches=None, pad_inches=0.5, frameon=None)
plt.subplots_adjust(hspace=0.4)

plt.subplot(212)   # Delete the subplot references to keep single plot mode
#plt.bar(center,log(twoFHist[0]+1, 10), align='center',alpha=0.5)
plt.semilogy(center, twoFHist[0], '.k', alpha=0.5)
plt.semilogy(twoFHist[1], nullDistNorml, '-.r', alpha=0.5)
plt.ylim( ( min(twoFHist[0]), max(twoFHist[0])) )
##plt.show()
plt.title('Semilog histogram for target ' + str(targName) + " (Job: " + str(jobId) + ")" )
plt.xlabel(r'$2\mathcal{F}$', fontsize=16)
plt.ylabel("Count", fontsize=16)
#plt.savefig("figures/cleaned_candidate_histogram_" + str(targName) + "_" + str(jobId) + ".png", dpi=None, facecolor='w', edgecolor='w', orientation='portrait', papertype=None, format="png", transparent=False, bbox_inches=None, pad_inches=0.5, frameon=None)
plt.savefig("figures/vetoed_line_" + str(targName) + "_" + str(jobId) + ".png", dpi=None, facecolor='w', edgecolor='w', orientation='portrait', papertype=None, format="png", transparent=True, bbox_inches=None, pad_inches=0.5, frameon=None)

##################################################
### End of pandasDump.py
##################################################
