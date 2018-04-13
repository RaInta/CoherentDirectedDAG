# -*- coding: utf-8 -*-
#------------------------------------------------------------------------------
#           Name: compCost.py
#         Author: Ra Inta, 20120609
#  Last Modified: 20120613, R.I.
#    Description: This analytically estimates the computational cost of a 
# search based on Tspan (the coherent integration time), the maximum search frequency
#  and the age of the target.
#
#------------------------------------------------------------------------------

from math import *
import os, string
from convertAstroToLAL import * # This is a separate Python script to convert RA and Dec. etc. from search_setup.xml
from readAstroDat import *
from numpy import array
from noiseData import *


#--------------------------------------------------------------------
# TODO: put this in search header file?


costTarget = 3.5 * 24 * 3600 # Target cost in CPU seconds


# -------------------------- Braking indices -----------------------

nMin = 2
nMax = 7

#--------------------------------------------------------------------


# Computational cost scalings for Fstat from actual code in the vicinity of Cas A parameters:
def costF(Tspan, fMax, TAUkyr):
    costF = costTarget * ( (fMax / 300.0) ** 2.2) * ( (0.3 / TAUkyr) ** 1.1 ) * ( (Tspan / 12.0) ** 4)
    return costF

# Rescaled for resampling using approximation ??? in resampling methods paper:
def costR(Tspan, fMax, TAUkyr):
    costR = costF(Tspan, fMax, TAUkyr) * math.log(fMax * TSPANsec(Tspan), 2 ) / (TSPANsec(Tspan) / 1800) # Check conversion factors (hours vs sec for Tspan)
    return costR


# Spin-down parameters ([Wette et al. 2008])


def f1Max(fMax, TAUkyr, nMin):
    f1Max = fMax / ( (nMin - 1) * float(TAUsec(TAUkyr)))
    return f1Max

def f2Max(fMax, fMin, TAUkyr, nMin, nMax):
    f2Max = nMax * ( (f1Max(fMax, TAUsec(TAUkyr), nMin) ** 2) / fMin )
    return f2Max

def f3Max(fMax, fMin, TAUkyr, nMin, nMax):
    f3Max = nMax * ( ((2 * f2Max(fMax, fMin, TAUsec(TAUkyr), nMin, nMax) * f1Max(fMax, TAUsec(TAUkyr), nMin) ) * (fMin ** 2 )) / (fMin - f1Max(fMax, TAUsec(TAUkyr), nMin) ** 3 )  )
    return f3Max

def mismatch(Tspan, fMax, fMin, TAUkyr, nMin, nMax):
    mismatch = 4*pow(pi,2)*array( [ pow(TSPANsec(Tspan),4)*(4.0/(6*6*5))*(pow(f1Max(fMax, TAUsec(TAUkyr), nMin), 2)), (pow(TSPANsec(Tspan), 6))*(9.0/(24*24*7))*(pow(f2Max(fMax, fMin, TAUsec(TAUkyr), nMin, nMax), 2) ), (pow(TSPANsec(Tspan), 8))*(16.0/(120*120*9))*(pow(f3Max(fMax, fMin, TAUsec(TAUkyr), nMin, nMax), 2)) ] )
    return mismatch

#---------------------------------------- #-------- Test output ----------------
#------------------------------------------------------------------------------

#------------------------------------- print "Cost Target: " + str( costTarget )
#----------------- print "Cost of F-stat (Cas A): " + str( costF(12, 300, 0.3) )
#------------- print "Cost of resampling (Cas A): " + str( costR(12, 300, 0.3) )
# print "Speed-up ratio of resampling (Cas A): " + str( costF(12, 300, 0.3)/costR(12, 300, 0.3) )


#--------------------------------------



#---------------------------- End of compCost.py ----------------

