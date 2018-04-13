#!/usr/bin/python
# -*- coding: utf-8 -*-
#------------------------------------------------------------------------------
#           Name: convertAstroToLAL.py
#         Author: Ra Inta, 20110909
#  Last Modified: 20120601, R.I.
#    Description: This takes astrophysical quantities from a common 'human-friendly'
# format to that useable by LALApps GW search code. 
#
# Note: I think it requires Python 2.5+ because of this usage of split() and partition().
# 
# 20120601 R.I. This has been modified from the original astroConvert.py to align with 
# Ben Owen's Mathematica notebook.
# 
#------------------------------------------------------------------------------

from math import pi, radians
from re import split, search


def TargName(GCoOrds):
    #Function to output target's name as the first part of its G-Co-ord
    TargName = split('\+|-', GCoOrds)[0] # Use {+,-} as delimiter
    return TargName

def RAdeg(JCoOrds):
    #Function to convert first half of J co-ord (hhmmss.ss... ) to RA in deg.
    RAstring = split('\+|-', JCoOrds)[0] # Can't rely on fixed J-co-ord precision; use {+,-} as delimiter
    RAhr = float(RAstring[0:2])
    RAmin = float(RAstring[2:4])
    RAsec = float(RAstring[4:len(RAstring)]) # J co-ords are given with variable precision at the arcsecond level
    RAdeg = (180.0/12) * (RAhr + RAmin/60 + RAsec/3600)
    return RAdeg

def DECdeg(JCoOrds):
    #Function to convert last half of J co-ord (+/-ddmmss.sss ...) to Dec. in deg.
    DECstring = split('\+|-', JCoOrds)[1]
    DECsign = search('\+|-', JCoOrds).group(0) # Get the sign of the Declination (Note: still a string type here)
    DECdd = float(DECstring[0:2])
    DECmm = float(DECstring[2:4])
    DECss = float(DECstring[4:len(DECstring)]) # Requires at least arc second resolution; need to change this to fail gracefully
    DECmag = DECdd + DECmm/60 + DECss/3600
    DECdeg = float(DECsign + "1") * DECmag 
    return DECdeg

def RArad(RAdeg):
    #Function to convert RA in degrees to radians
    RArad = radians(RAdeg)
    return RArad

def DECrad(DECdeg):
    #Function to convert Dec. in degrees to radians
    DECrad = radians(DECdeg)
    return DECrad

def TAUsec(TAUkyr):
    #Function to convert TAU in kyr to seconds
    TAUsec = float(TAUkyr) * 1E3 * 365.25 * 24 * 3600
    return TAUsec

def TSPANsec(TSPANd):
    #Function to convert TSPAN in days to seconds
    TSPANsec = float(TSPANd) * 24 * 3600
    return float(TSPANsec)

def TSPANd(TSPANsec):
    #Function to convert TSPAN in seconds to days
    TSPANd = float(TSPANsec) / (24 * 3600)
    return float(TSPANd)

def DISTm(DISTkpc):
    #Function to convert DIST in kpc to metres
    DISTm = float(DISTkpc) * 3.08568025E19
    return DISTm


##---------------Test mode only ------------

#TAUkyr = 3
#TSPANd = 10 
#DISTkpc = 3
#JCoOrds = "085231.2873-462254.3446"

#print "J co-ords: ", JCoOrds

#print "Age in sec: ", TAUsec(TAUkyr), "\n"

#print "T_span in days: ", TSPANd
#print "T_span in sec: ", TSPANsec(TSPANd), "\n"
#print "Distance in metres: ", DISTm(DISTkpc), "\n"
#print "RA in deg: ", RAdeg(JCoOrds)
#print "Dec. in deg: ", DECdeg(JCoOrds)

#print "RA in radians: ", RArad(RAdeg(JCoOrds))
#print "Declination in radians: ", DECrad(DECdeg(JCoOrds))

##----------------------------------------------


# End of convertAstroToLAL.py
