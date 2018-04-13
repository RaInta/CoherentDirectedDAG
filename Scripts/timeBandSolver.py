# -*- coding: utf-8 -*-
#------------------------------------------------------------------------------
#           Name: timeBandSolver.py
#         Author: Ra Inta, 20120609 and Andrew Lundgren, 20120627
#  Last Modified: 20120629, A.L.
#    Description: This is a simple iterative solver to walk up the LIGO noise curve, finding the 
# frequency bounds while keeping computational cost below the target. It runs as follows:
#
#   1: Find Tspan and resulting h95 as a function of fMax
#   2: Find maximum fMax and the associated Tspan that beats spindown
#   3: Find fMin that beats spindown for above Tspan
#
#------------------------------------------------------------------------------


from math import sqrt
from convertAstroToLAL import * # This is a separate Python script to convert RA and Dec. etc. from search_setup.xml
#===============================================================================
# from upperLimitCalcs import *
#===============================================================================

tSpanCasA = TSPANsec(12) # 12 days
hCasA = 1.22e-24
ageCasA = 0.3 # kyr
distCasA = 3.4 # kpc
fCasA = 300 # Hz
costCasA = 3.5*24*3600 # 3.5 days in seconds
livetimeFracCasA = 12.0 / 19.2
from math import log


class astroTarget:
    def __init__(self, Dkpc, TAUkyr):
        self._Dkpc = Dkpc
        self._TAUkyr = TAUkyr
        self.hAge = hCasA * (distCasA / Dkpc) * pow(TAUkyr / ageCasA, -0.5)
    def calcTSpan(self, costTarget, fMax):
        #costScaling = pow(fMax / fCasA, -2.2) * pow(self._TAUkyr / ageCasA, 1.1)
        #return int(tSpanCasA*pow((costCasA / costTarget)*costScaling,0.25))
        costScaling = pow(fMax / fCasA, -2.2) * pow(self._TAUkyr / ageCasA, 1.1)
        return int(tSpanCasA*pow((costCasA / costTarget)*costScaling, 0.3333) * log( ( fMax * self._TAUkyr ) / (fCasA * ageCasA), 2) )
    def h95(self, tSpan, theta, PSD):
        return theta * pow(livetimeFracCasA * PSD / tSpan, 0.5)


def timeBand(Dkpc, TAUkyr, costTarget, fNoise, psdNoise, fBucket, theta):
    """Returns fMin (Hz), fMax (Hz), Tspan (seconds)

    Arguments are target distance (kpc), target age (kyr)
    Desired computational cost of search (seconds)
    Lists containing f (Hz) and PSD[f] (strain^2 / Hz)
    Bucket frequency (Hz)
    theta <- function that returns theta[f]

    """

    target = astroTarget(Dkpc, TAUkyr)

    # Estimate the sensitivity for a variety of fmax
    estimates = []
    for (fval, psdVal) in zip(fNoise, psdNoise):
        if fval >= fBucket:
            myTSpan = target.calcTSpan(costTarget, fval)
            myh95 = target.h95(myTSpan, theta(fval), psdVal)
            estimates.append((fval, myTSpan, myh95))

    # Select the choices of tSpan that beat the spindown limit
    doable = filter(lambda x: x[2] <= target.hAge, estimates)

    if len(doable) > 0: # The search is possible
        doable.sort(key = lambda x: x[0], reverse = True)
        myFMax, myTspan, myh95 = doable[0]
        myFMin = min([f for f, psdVal in zip(fNoise, psdNoise) \
                if target.h95(myTspan, theta(myFMax), psdVal) <= target.hAge])
    else: # Search is not possible
        myFMin = myFMax = myTspan = 0

    return myFMin, myFMax, myTspan




#--------------------------- Test output   ----------------------------------
#--------------------------------------------------------- print timeBand(10, 2)

# print "fMin (Hz), fMax (Hz), Tspan (days): " + str( timeBand(10, 1, costTarget, hNoiseFit, fBucket, theta)[2] )

#------------------ print "Fstat cost: " + str( costF(myTspan, myFMax, TAUkyr) )
#--------------------------------------- print "Target cost: " + str(costTarget)


# ------------------- End of timeBandSolver.py -------------------------------
