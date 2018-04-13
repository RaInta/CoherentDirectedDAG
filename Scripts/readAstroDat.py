# -*- coding: utf-8 -*-
#------------------------------------------------------------------------------
#           Name: readAstroDat.py
#         Author: Ra Inta, 20110909
#  Last Modified: 20120611
#    Description: This is a script to just read astro data from a text file to be used for
# a directed GW search
#
# 20120601 R.I.: This has been converted from the script searchXMLgen.py to align with Ben Owen's
# Mathematica notebook.
#
#------------------------------------------------------------------------------

from math import pi
import os, string
from convertAstroToLAL import * # This is a separate Python script to convert RA and Dec. etc. from search_setup.xml



# 1: reads from input textfile TargName GCoOrds JCoOrds D(kpc) Tau(kyr)
# Note that the text file needs to be in column format TARGname, RAdeg, DECdeg, TAUkyr, DISTkpc, TSPANd
# Directories will be created for each target
#
# 2: open a files, called ' search_setup.xml ', per target and populate with data from targetList.txt
# You can then run searches from each of these directories.


# Column format of text file:
# GCoOrds JCoOrds DISTkpc TAUkyr
# Note that the J Co-ord parser uses +/- as a delimiter--this is for variable precision observations

GCoOrds = []
JCoOrds = []
DISTkpc = []
TAUkyr = []
TargNames = []

for lines in open("astro-targets-converted.dat", 'r').readlines():
    if not lines[0] == '#':
        eachLine = string.split(lines)
        TargNames.append(eachLine[0])
        GCoOrds.append(eachLine[1]) 
        JCoOrds.append(eachLine[2])
        DISTkpc.append(eachLine[3])
        TAUkyr.append(eachLine[4])
    
def TargNameStr(GCoOrds):
    TargNameStr = TargName(GCoOrds)
    return TargNameStr

def RAlal(JCoOrds):        
    RAlal = RArad(RAdeg(JCoOrds))        
    return RAlal

def DEClal(JCoOrds):
    DEClal = DECrad(DECdeg(JCoOrds))
    return DEClal

def TAUlal(TAUkyr):
    TAUlal = TAUsec(TAUkyr)
    return TAUlal

def DISTlal(DISTkpc):
    DISTlal = DISTm(DISTkpc)
    return DISTlal



##---------------Test mode only ------------


#TAUkyr = 3
#TSPANd = 10 
#DISTkpc = 3
#JCoOrds = "085231.2-462254.3"

#===============================================================================
# print "-----------Test example------------"
# print "Age in sec: ", str(TAUlal(TAUkyr))
# print "Target name: ", str(TargNameStr(GCoOrds))
# print "Distance in metres: ", DISTm(DISTkpc)
# print "RA in rad.: ", RAlal(JCoOrds)
# print "Dec. in rad.: ", DEClal(JCoOrds)
# print "------End of test ----------------"
#===============================================================================


#print "RA in radians: ", RArad(RAdeg(JCoOrds))
#print "Declination in radians: ", DECrad(DECdeg(JCoOrds))
    

#-------------------- tests for I/O

#Fmin = 20
#Fmax = 1000
#TARGlist = ["Beeblebrox3", "WonTon2", "ObiWannaGo"]


##----------------------------------------------



# End readAstroDat.py
