# -*- coding: utf-8 -*-
#------------------------------------------------------------------------------
#           Name: setupSearchDirectoriesAndXMLs.py
#         Author: Ra Inta, 20110909
#  Last Modified: 20120601
#    Description: This is a script to generate search_setup.xml files from a 
# text file of parameters to populate, placing them in their respective directories
# in the process.
#
# 20120601 R.I.: This has been converted from the script searchXMLgen.py to align with Ben Owen's
# Mathematica notebook.
#
# Note that the XML output is clumsily implemented here; a text file is created to mimic
# the XML format, rather than being handled natively.
#------------------------------------------------------------------------------

from math import pi
import os, string
from convertAstroToLAL import * # This is a separate Python script to convert RA and Dec. etc. from search_setup.xml
from readAstroDat import * # Get astrophysical data
from timeBandSolver import *
from compCost import *
from noiseData import *

def thetaFit(fval):
    return 0.8 * 31.0 * (1.0 + 0.1*(fval - 676.0)/(676.0-87.0))


# 1: reads from input astro-targets-converted.dat text file Note that the text
# file needs to be in column format TARGname, RAdeg, DECdeg, TAUkyr, DISTkpc,
# TSPANd (lines commented with a '#' are ignored).  Directories will be created
# for each target.
#
# 2: In each target directory, makes subdirectories "low" and "high" for first
# iteration to get sensitivity, "full" for second iteration with fine tuned
# sensitivity. Each subdirectory gets a search_setup.xml with first-iteration
# parameters, though "full" will need 3 edits by hand later.

#------------------------------------------------------------------------------ 
#---------------- This section produces the setup XML --------------------------


for targIdx in range(len(GCoOrds)):
    eachTargName = TargNames[targIdx]
    targDirName = eachTargName
    eachJCoOrd = JCoOrds[targIdx]
    eachDISTkpc = float(DISTkpc[targIdx])
    eachTAUkyr =  float(TAUkyr[targIdx])
    minFreq, maxFreq, myTSpan = timeBand(eachDISTkpc, eachTAUkyr, costTarget, fNoise, hNoise, fBucket, thetaFit)
    if minFreq <= 0:
        continue
    freqBand = maxFreq - minFreq
    if not os.path.exists(targDirName):
        os.makedirs(targDirName + "/low")
        XMLfilename = targDirName + "/low/search_setup.xml"
        FILE = open(XMLfilename,"w")
        FILE.write( "<?xml version='1.0'?>\n")
        FILE.write( "<setup>\n")
        FILE.write( " <target comment=\"" + eachTargName + "\">\n")
        FILE.write( "  <right_ascension comment=\"" + "{0:.2f}".format( RAdeg(eachJCoOrd) ) + " degrees \">" + str( RArad( RAdeg(eachJCoOrd) ) ) + "</right_ascension>\n")
        FILE.write( "  <declination comment=\"" + "{0:.2f}".format( DECdeg(eachJCoOrd) ) + " degrees \">" + str( DECrad( DECdeg(eachJCoOrd) ) ) + "</declination>\n")
        FILE.write( "  <spindown_age comment=\"Same as est. SNR age: " + "{0:.2f}".format( eachTAUkyr ) + " kyr \">" + str( TAUsec(eachTAUkyr) ) + "</spindown_age>\n")
        FILE.write( "  <distance comment=\"" + "{0:.2f}".format( eachDISTkpc ) + " kpc \">" + str( DISTm(eachDISTkpc) ) + "</distance>\n")
        FILE.write( "  <moment_of_inertia comment=\"Same as Cas A\">1.0e38</moment_of_inertia>\n")
        FILE.write( "  <min_braking comment=\"Same as Cas A\">" + str(nMin) + "</min_braking>\n")
        FILE.write( "  <max_braking comment=\"Same as Cas A\">" + str(nMax) + "</max_braking>\n")
        FILE.write( " </target>\n")
        FILE.write( " <search comment=\"Search parameters\">\n")
        FILE.write( "  <freq comment=\"Lower frequency bound\">" + str(minFreq) + "</freq>\n")
        if minFreq < 100:
            FILE.write( "  <band comment=\" Frequency band\">" + str(40) + "</band>\n")
        else:
            FILE.write( "  <band comment=\" Frequency band\">" + str(20) + "</band>\n")
        FILE.write( "  <max_mismatch comment=\"Same as Cas A\">0.2</max_mismatch>\n")
        FILE.write( "  <span_time comment=\"" + "{0:.2f}".format( TSPANd( myTSpan ) ) + " days\">" + str(myTSpan) + "</span_time>\n")
        FILE.write( "  <keep_threshold comment=\"1 in a million\">33.3768</keep_threshold>\n")
        FILE.write( "  <rng_med_window comment=\"Updated for O1\">25</rng_med_window>\n")
        FILE.write( "  <ephem_year comment=\"Range for S6 SFTs\">00-19-DE405</ephem_year>\n")
        FILE.write( " </search>\n")
        FILE.write( " <upper_limit comment=\"Parameters of the upper limits\">\n")
        FILE.write( "  <veto_thresh comment=\"Standard deviations\">6</veto_thresh>\n")
        FILE.write( "  <band comment=\"double Cas A\">1.0</band>\n")
        FILE.write( "  <false_dismissal comment=\"Same as Cas A\">0.05</false_dismissal>\n")
        FILE.write( "  <num_injections comment=\"Same as Cas A\">6000</num_injections>\n")
        FILE.write( " </upper_limit>\n")
        FILE.write( "</setup>\n")
        FILE.close()
        os.makedirs(targDirName + "/high")
        XMLfilename = targDirName + "/high/search_setup.xml"
        FILE = open(XMLfilename,"w")
        FILE.write( "<?xml version='1.0'?>\n")
        FILE.write( "<setup>\n")
        FILE.write( " <target comment=\"" + eachTargName + "\">\n")
        FILE.write( "  <right_ascension comment=\"" + "{0:.2f}".format( RAdeg(eachJCoOrd) ) + " degrees \">" + str( RArad( RAdeg(eachJCoOrd) ) ) + "</right_ascension>\n")
        FILE.write( "  <declination comment=\"" + "{0:.2f}".format( DECdeg(eachJCoOrd) ) + " degrees \">" + str( DECrad( DECdeg(eachJCoOrd) ) ) + "</declination>\n")
        FILE.write( "  <spindown_age comment=\"Same as est. SNR age: " + "{0:.2f}".format( eachTAUkyr ) + " kyr \">" + str( TAUsec(eachTAUkyr) ) + "</spindown_age>\n")
        FILE.write( "  <distance comment=\"" + "{0:.2f}".format( eachDISTkpc ) + " kpc \">" + str( DISTm(eachDISTkpc) ) + "</distance>\n")
        FILE.write( "  <moment_of_inertia comment=\"Same as Cas A\">1.0e38</moment_of_inertia>\n")
        FILE.write( "  <min_braking comment=\"Same as Cas A\">" + str(nMin) + "</min_braking>\n")
        FILE.write( "  <max_braking comment=\"Same as Cas A\">" + str(nMax) + "</max_braking>\n")
        FILE.write( " </target>\n")
        FILE.write( " <search comment=\"Search parameters\">\n")
        FILE.write( "  <freq comment=\"Lower frequency bound\">" + str(maxFreq-10) + "</freq>\n")
        FILE.write( "  <band comment=\" Frequency band\">" + str(10) + "</band>\n")
        FILE.write( "  <max_mismatch comment=\"Same as Cas A\">0.2</max_mismatch>\n")
        FILE.write( "  <span_time comment=\"" + "{0:.2f}".format( TSPANd( myTSpan ) ) + " days\">" + str(myTSpan) + "</span_time>\n")
        FILE.write( "  <keep_threshold comment=\"1 in a million\">33.3768</keep_threshold>\n")
        FILE.write( "  <rng_med_window comment=\"Same as Cas A\">50</rng_med_window>\n")
        FILE.write( "  <ephem_year comment=\"Range for S6 SFTs\">09-11-DE405</ephem_year>\n")
        FILE.write( " </search>\n")
        FILE.write( " <upper_limit comment=\"Parameters of the upper limits\">\n")
        FILE.write( "  <veto_thresh comment=\"Standard deviations\">6</veto_thresh>\n")
        FILE.write( "  <band comment=\"double Cas A\">1.0</band>\n")
        FILE.write( "  <false_dismissal comment=\"Same as Cas A\">0.05</false_dismissal>\n")
        FILE.write( "  <num_injections comment=\"Same as Cas A\">6000</num_injections>\n")
        FILE.write( " </upper_limit>\n")
        FILE.write( "</setup>\n")
        FILE.close()
	os.makedirs(targDirName + "/full")
        XMLfilename = targDirName + "/full/search_setup.xml"
        FILE = open(XMLfilename,"w")
        FILE.write( "<?xml version='1.0'?>\n")
        FILE.write( "<setup>\n")
        FILE.write( " <target comment=\"" + eachTargName + "\">\n")
        FILE.write( "  <right_ascension comment=\"" + "{0:.2f}".format( RAdeg(eachJCoOrd) ) + " degrees \">" + str( RArad( RAdeg(eachJCoOrd) ) ) + "</right_ascension>\n")
        FILE.write( "  <declination comment=\"" + "{0:.2f}".format( DECdeg(eachJCoOrd) ) + " degrees \">" + str( DECrad( DECdeg(eachJCoOrd) ) ) + "</declination>\n")
        FILE.write( "  <spindown_age comment=\"Same as est. SNR age: " + "{0:.2f}".format( eachTAUkyr ) + " kyr \">" + str( TAUsec(eachTAUkyr) ) + "</spindown_age>\n")
        FILE.write( "  <distance comment=\"" + "{0:.2f}".format( eachDISTkpc ) + " kpc \">" + str( DISTm(eachDISTkpc) ) + "</distance>\n")
        FILE.write( "  <moment_of_inertia comment=\"Same as Cas A\">1.0e38</moment_of_inertia>\n")
        FILE.write( "  <min_braking comment=\"Same as Cas A\">" + str(nMin) + "</min_braking>\n")
        FILE.write( "  <max_braking comment=\"Same as Cas A\">" + str(nMax) + "</max_braking>\n")
        FILE.write( " </target>\n")
        FILE.write( " <search comment=\"Search parameters\">\n")
        FILE.write( "  <freq comment=\"Lower frequency bound\">" + str(minFreq) + "</freq>\n")
        FILE.write( "  <band comment=\" Frequency band\">" + str(freqBand) + "</band>\n")
        FILE.write( "  <max_mismatch comment=\"Same as Cas A\">0.2</max_mismatch>\n")
        FILE.write( "  <span_time comment=\"" + "{0:.2f}".format( TSPANd( myTSpan ) ) + " days\">" + str(myTSpan) + "</span_time>\n")
        FILE.write( "  <keep_threshold comment=\"1 in a million\">33.3768</keep_threshold>\n")
        FILE.write( "  <rng_med_window comment=\"Same as Cas A\">50</rng_med_window>\n")
        FILE.write( "  <ephem_year comment=\"Range for S6 SFTs\">09-11-DE405</ephem_year>\n")
        FILE.write( " </search>\n")
        FILE.write( " <upper_limit comment=\"Parameters of the upper limits\">\n")
        FILE.write( "  <veto_thresh comment=\"Standard deviations\">6</veto_thresh>\n")
        FILE.write( "  <band comment=\"double Cas A\">1.0</band>\n")
        FILE.write( "  <false_dismissal comment=\"Same as Cas A\">0.05</false_dismissal>\n")
        FILE.write( "  <num_injections comment=\"Same as Cas A\">6000</num_injections>\n")
        FILE.write( " </upper_limit>\n")
        FILE.write( "</setup>\n")
        FILE.close()
    else:
        print "Directory " + targDirName + " already exists, skipping..."

#------------------------------------------------------------------------------ 



#------------------------------------------------------------------------------ 
##---------------Test mode only ------------



# --- tests for astroConvert.py -----

#TAUkyr = 3
#TSPANd = 10 
#DISTkpc = 3
#JCoOrds = "085231.2-462254.3"

#print "Age in sec: ", TAUsec(TAUkyr), "\n"
#print "T_span in sec: ", TSPANsec(TSPANd), "\n"
#print "Distance in metres: ", DISTm(DISTkpc), "\n"
#print "RA in deg: ", RAdeg(JCoOrds), "\n"
#print "Dec. in deg: ", DECdeg(JCoOrds), "\n"

#print "RA in radians: ", RArad(RAdeg(JCoOrds))
#print "Declination in radians: ", DECrad(DECdeg(JCoOrds))



#-------------------- tests for I/O

#Fmin = 20
#Fmax = 1000
#TARGlist = ["Beeblebrox3", "WonTon2", "ObiWannaGo"]


##----------------------------------------------





#-------------------------- End searchXMLgen.py -------------------
