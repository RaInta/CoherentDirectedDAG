#!/usr/bin/python

#------------------------------------------------------------------------------
#           Name: getThresh.py
#         Author: Ra Inta, 20150716
#  Last Modified: 20150716
# This is a pared down version of lookThresh.py. This is used to give
# an estimate of the (95%) 2F threshold for a given number of templates
#This is to calculate the 'further look' threshold for the maximum 2F value from a directed CW gravitational wave search.
# It also creates a top_jobs.txt list of candidates and generates figures in a newly created 'figures' folder.
#------------------------------------------------------------------------------

from scipy.stats import chi2
import numpy as np
from math import pow
import os
from sys import argv

# the only input parameter is the total number of templates
Ntot = float(argv[1])

if argv[2]:
    max2F = float(argv[2])

if argv[3]:
    effective_ratio = float(argv[3])
else:
    effective_ratio = 1.0



# Kludge approach: specify support for 2F
# TODO come up with a way to do this without a priori support
min2Fthresh = 30
max2Fthresh = 400



############################################################
#1) Find further look threshold by evaluating where [ CDF(Chi2(Neff,4))== \alpha ] for confidence level \alpha
############################################################

# Simple theoretical probability the overall max2F came from Gaussian noise
def prob(N, max2F):
   """Works out the probability given a number of templates and a maximum twoF"""
   littleP = 1 - chi2.cdf(max2F, 4)
   return N * littleP * pow(chi2.cdf(max2F, 4) , N )

if max2F:
    P2Fmax = 1 - chi2.cdf(max2F, 4)
    Pval = prob( Ntot * effective_ratio, max2F)
    max2F_string = 'Maximum 2F value overall: 2F_max=' + str(max2F) + '\n'
    prob2F_string = 'Probability of this in Gaussian noise: P(2F_max)=' + str(Pval) +'\n'
else:
    max2F_string = ''
    prob2F_string = ''


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


lookThresh = getLookThresh(Ntot*effective_ratio, min2Fthresh, max2Fthresh)

############################################################


############################################################
# 2) Display  everything
############################################################

print("Total number of templates: " + str( Ntot ) )
print("Effective ratio: " + str(effective_ratio) )
print(max2F_string + prob2F_string)
print("Further look theshold: " + str( lookThresh ) )




############################################################
#  End of lookThresh.py
############################################################
