#!/usr/bin/python

#------------------------------------------------------------------------------
#           Name: collateSearchResults.py
#         Author: Ra Inta, 20151007
#  Last Modified: 20160520, R.I.
#
# This is designed to speed up the collation procedure in coherent directed
# searches. The precursor is the PostCasA modified CollateSearchResults.pl
# script originally written by Karl Wette.
# This is designed to easily add various levels of veto. It currently
# takes in fscan veto populated veto_bands.xml file and also applies
# the 'IFO-veto' check, populating veto_bands.xml if necessary.
# It reads in setup XMLs as well as veto and search results.
# It creates and populates the upper_limit_bands.xml file.
#
#------------------------------------------------------------------------------

# The C versions of Element Tree are faster (but not always supported)
try:
    import xml.etree.cElementTree as ET
except ImportError:
    import xml.etree.ElementTree as ET
try:
    from xml.etree.cElementTree import Element, SubElement, Comment, tostring
except ImportError:
    from xml.etree.ElementTree import Element, SubElement, Comment, tostring

import bz2
from intervaltree import Interval,IntervalTree
import os
import re
from math import ceil,cos


# For timing:
import time

start_time = time.clock()

############################################################
# 0) Read in some basic setup information
############################################################


# TODO read this from setup file---i.e. add to setup file?
JOBS_PER_SUBDIR=250 # For the moment this is hard-coded here (following the style of two other scripts in the pipeline).
alpha_stat=0.05  # Statistical alpha (confidence = 1 - alpha_stat ). Hard-coded here, but easy enough to read this from setup.

# The CFSv2 column output can be modified, depending on the flags you used to run it
columnIdx = ["freq", "alpha", "delta", "f1dot", "f2dot", "f3dot", "twoF", "log10BSGL", "twoF_H1", "twoF_L1"]

# Get parameters from search_setup.xml
with open('../../search_setup.xml','r') as searchSetup:
    setup_tree = ET.parse( searchSetup )
    setup_root = setup_tree.getroot()

for search_params in setup_root.iter('search'):
    search_band = float( search_params.find('band').text )
    start_freq = float( search_params.find('freq').text )
    Tspan = float( search_params.find('span_time').text )

for ul_params in setup_root.iter('upper_limit'):
    ul_band = float( ul_params.find('band').text )

NUM_UL_BANDS = int( ceil( search_band / ul_band ) )

############################################################
# 1) Take in search results and vetoes
############################################################

with bz2.BZ2File('../../search_bands.xml.bz2', 'rb') as searchBandsFile:
    search_tree = ET.parse( searchBandsFile )
    search_root = search_tree.getroot()


############################################################
# ElementTree doesn't pretty-print XML! Need to add indents.
# Stolen directly from:
# http://stackoverflow.com/questions/749796/pretty-printing-xml-in-python
############################################################
def indent(elem, level=0):
    """This is a function to make the XML output pretty, with the right level
    of indentation"""
    i = "\n" + level*"  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

############################################################


# Create upper limit bands
upper_limit_root = ET.Element("upper_limit_bands")

for jobUL in range( NUM_UL_BANDS ):
   ul_band_job = SubElement(upper_limit_root, "upper_limit_band")
   indent(ul_band_job, 1)
   ul_Idx = SubElement(ul_band_job, "job")
   ul_Idx.text = str( jobUL )
   indent(ul_Idx, 2)
   ul_Idx = SubElement(ul_band_job, "freq")
   ul_Idx.text = str( start_freq + jobUL*ul_band )
   indent(ul_Idx, 2)
   ul_Idx = SubElement(ul_band_job, "band")
   ul_Idx.text = str( ul_band )
   indent(ul_Idx, 2)


## Walk through the XML tree for job, 2F and f0; don't pick up the vetoed bands.
search_segments = []

for jobNumber in search_root.iter('search_band'):
    search_jobNum = int( jobNumber.find('job').text )
    search_startFreq = float( jobNumber.find('freq').text )
    search_endFreq = search_startFreq + float( jobNumber.find('band').text )
    search_segments.append( (search_startFreq, search_endFreq, search_jobNum) )

# Read the veto_bands XMl file and create an array of tuples containing vetoed bands
with open('../../veto_bands.xml', 'r') as vetoFile:
    veto_tree = ET.parse( vetoFile )
    veto_root = veto_tree.getroot()

veto_segments = []

for vetoBand in veto_root.iter('veto_band'):
    veto_startFreq = float( vetoBand.find('freq').text )
    veto_endFreq = veto_startFreq + float( vetoBand.find('band').text )
    veto_power =  vetoBand.find('power').text
    veto_segments.append( (veto_startFreq, veto_endFreq, veto_power) )
    #veto_segments.append( (veto_startFreq, veto_endFreq ) )

ul_segments = []

for ulBand in upper_limit_root.iter('upper_limit_band'):
    ul_jobNum = int( ulBand.find('job').text )
    ul_startFreq = float( ulBand.find('freq').text )
    ul_endFreq =  ul_startFreq + float( ulBand.find('band').text )
    ul_segments.append( (ul_startFreq, ul_endFreq, ul_jobNum) )

############################################################
# 2) make interval trees to compare search and veto bands
############################################################


# Create interval trees from search, veto and upper limit bands
search_interval = IntervalTree.from_tuples( search_segments ) # O( n*log(n) )
veto_interval = IntervalTree.from_tuples( veto_segments )
ul_interval = IntervalTree.from_tuples( ul_segments ) # O( n*log(n)


# Remove vetoed bands from search_bands
search_interval.update( veto_interval ) # O( v*log(n) ), v is number of vetoes
search_interval.split_overlaps()  # O( n*log(n) ), best case, where
[search_interval.remove_overlap(a[0], a[1]) for a in veto_interval] # O( (v + v_band)*log(n) ), v_band is range of vetoing (usually ~1% of band)


# Slice the search band intervals along upper limit band boundaries
# Why? This is a trick so we don't have to check for upper limit boundaries
# when we trawl through each search segment. Note that this is sped up under the
# assumption that the upper limit bandwidths are generally much larger than the search
# bandwidths.
for a in ul_interval:
    search_interval.slice(a[0])


# Easy to remove veto segments from upper limit bands too!
# TODO ask Ben+Teviet etc. for go-ahead
# Just need to uncomment the following three lines:
ul_interval.update( veto_interval ) # O( v*log(n) ), v is number of vetoes
ul_interval.split_overlaps()  # O( n*log(n) ), best case, where
[ul_interval.remove_overlap(a) for a in veto_interval] # O( (v + v_band)*log(n) ), v_band is range of vetoing (usually ~1% of band)


############################################################
# 3) Iterate over search jobs
############################################################
#
# Doing this *after* vetoing means we don't care if we didn't submit
# the search job for it etc.


# Get template covering band
def template_covering_band(loudestLine, Tspan):
    freq = float(loudestLine[0])
    delta = float(loudestLine[2])
    f1dot = float(loudestLine[3])
    f2dot = float(loudestLine[4])
    f3dot = float(loudestLine[5])
    dfSpin = (f3dot/6)*pow(Tspan,3) + (f2dot/2)*pow(Tspan,2) + f1dot*Tspan
    # extra frequency band due to sidereal Doppler motion
    # constant is (earth radius)*(sidereal angular frequency)/c
    # assume detector is at equator (cos latitude = 1)
    dfDoppl = 1.55e-6 * cos( delta ) * max(freq, freq + dfSpin)
    f0 = min( freq, freq + dfSpin ) - dfDoppl
    f1 = max( freq, freq + dfSpin ) + dfDoppl
    return str(f0),str(f1-f0)


ifo_v_jobs = ''  # Initialise the ifo-vetoed jobs list
prev_jobNum = -1  # Keep track of the previous job number
prev_ulNum = -1  # Keep track of the previous job number
segmentCounter = 0
sorted_searchBands = sorted( search_interval )
sorted_ulBands = sorted( ul_interval )

# The main loop:
for searchBand in sorted_searchBands:
    jobNum = searchBand[2]
    # Find the respective upper limit job number by querying the frequency at the beginning of the search job
    ulSegment = sorted( ul_interval[searchBand[0]] )[0]
    ulNum = ulSegment[2]
    #subDir = "jobs/search/" + str( int( jobNum )/JOBS_PER_SUBDIR )
    subDir = str( int( jobNum )/JOBS_PER_SUBDIR )
    jobFileName = subDir + "/search_results.txt." + str( jobNum )
    if ( jobNum > prev_jobNum ):    # Initialise if we've moved to a new job number
        IFOvetoed = 0
        max2F = 0.0
        loudestLine = ''
        numTemplates = ''
        # check job has been submitted
        if os.path.isfile( subDir + "/search.sub." + str( jobNum ) ):
            print "Job " + str( jobNum ) + " not submitted"
            break
        # check job files are all present
        for logFileName in ("/condor.out.", "/search.log.", "/search_results.txt.", "/search_histogram.txt.", "/condor.err."):
            logFileName = subDir + logFileName + str( jobNum )
            if not os.path.isfile( logFileName ):
                print "Search file " + logFileName + " does not exist!"
                break
        # check error files are empty
        #print(logFileName)
        if os.path.getsize( logFileName ) > 0:
            print "Condor error file " + logFileName + " is not empty!"
            break
        # check search.log.$job, check for number of templates and last line
        with open( subDir + "/search.log." + str( jobNum ), 'r' ) as logFile:
            #logFile.seek(-100,2) # Skip right to 100B before the end of the file; only do this for large files
            lastLine = False
            for eachLine in logFile:
                if re.match( "^.*Counting spindown lattice templates \.\.\.", eachLine):
                    singleLine = eachLine.split()
                    numTemplates = singleLine[-1]
                if re.match("^.*\[debug\]: Freeing Doppler grid \.\.\. done", eachLine) or re.match("^.*\[debug\]: Loading SFTs \.\.\. done",eachLine):
                    lastLine = True
            if not lastLine:
                print("No last line of search.log." + str( jobNum ) )
            if not numTemplates:
                print( "No number of templates in search.log." + str( jobNum ) )
        # check last line of search_results.txt.$job and search_histogram.txt.$job
        for jobFileSpecifier in ("histogram", "results"):
            jobFileName = subDir + "/search_" + jobFileSpecifier + ".txt." + str( jobNum )
            lastLine = False
            with open(jobFileName,"r") as jobFile:
                # Go to end of the file, check last line
                jobFile.seek(-30,2)
                for line in jobFile:
                    if re.match( "%DONE$", line):
                        lastLine = True
                if not lastLine:
                    print("No last line of " + jobFileName )
                    break
    # TODO may need to flush jobFile (uncomment next line)
    # jobFile.flush()
    # Do the same for the upper limit band
    if ( ulNum > prev_ulNum ):    # Initialise if we've moved to a new upper limit job
        max2F_ul = 0.0
        loudestLine_ul = ''
        numTemplates_ul = ''
    # Look for max2F, in search and/or upper limits from the current segment
    with open(jobFileName,"r") as jobFile:
        for line in jobFile:
            eachLine = line.split()
            if not (eachLine[0][0] == "%"):
                twoF = float( eachLine[6] )
                f0 = float(template_covering_band(eachLine, Tspan)[0])
                f0Band = float(template_covering_band(eachLine, Tspan)[1])
                # Check if template is IFO vetoed
                if (float( eachLine[8] ) >= twoF or float( eachLine[9] ) >= twoF ):
                    IFOvetoed += 1
                    twoF = 0.0  # Just so upper limit loop doesn't have to do the same check...
                # Make sure the covering band is in the search band segment
                #elif ( ( searchBand[0] <= f0 ) and ( f0+f0Band <= searchBand[1] ) ):
                elif ( ( searchBand[0] <= float(eachLine[0]) ) and ( float(eachLine[0]) <= searchBand[1] ) ):
                    if twoF > max2F:
                        max2F = twoF
                        loudestLine = eachLine
                        print("Job: "+ str(jobNum)+" New twoF: "+ str(max2F)+ " Looking from (serach,cover): ("+str(searchBand[0])+", "+str(f0)+ ") to (search, cover): ("+ str(searchBand[1])+", "+str(f0+f0Band)+ ") Hz" )
                # Check the upper limit band segment
                if ( (ulSegment[0] <= f0 ) and (f0+f0Band <= ulSegment[1]) ):
                    if twoF > max2F_ul:
                        max2F_ul = twoF
                        loudestLine_ul = eachLine
    # Check to see if it's the last search segment in the job, or the very last search segment
    if ( searchBand == sorted_searchBands[-1] or jobNum < sorted_searchBands[ segmentCounter + 1 ][2] ):
        # Add to search_bands XML file (even if no template survives)
        for searchJobElement in search_root:
            for searchJobSubElement in searchJobElement.iter('job'):
                if searchJobSubElement.text == str( jobNum ):
                    loudestEl = SubElement( searchJobElement,"loudest_nonvetoed_template")
                    indent(loudestEl, 1)
                    currentSearchJobEl = searchJobElement
        # Spit the dummy if IFOvetoed >= alpha_stat*numTemplates:
        if float( IFOvetoed ) >= alpha_stat*float( numTemplates ):
            # reset loudestLine and max2F, open and add searchBand
            # limits to veto_bands.xml
            print("Warning! IFO-vetoed entire job : " + str( jobNum ) )
            IFOvetoed = 0
            max2F = 0.0
            loudestLine = ''
            # Append to ifo_v_jobs.txt counter
            ifo_v_jobs += str(jobNum) + "\n"
            veto_segments.append( searchBand[0:2])
            for jobIdx in search_root.iter('search_band'):
                if int( jobIdx.find('job').text ) == jobNum:
                    vetoIdx = SubElement( veto_root, "veto_band")
                    indent(vetoIdx, 2)
                    vetoIdx.set('comment', 'IFO_veto')
                    vetoIdx_band = SubElement( vetoIdx, "band")
                    vetoIdx_band.text = jobIdx.find('band').text
                    indent(vetoIdx_band, 3)
                    vetoIdx_band = SubElement( vetoIdx, "freq")
                    vetoIdx_band.text = jobIdx.find('freq').text
                    indent(vetoIdx_band, 3)
                    SubElement( currentSearchJobEl,"num_templates").text = numTemplates
                    indent(loudestEl, 1)
                    SubElement( currentSearchJobEl,"num_templates_vetoed").text = numTemplates
                    indent(loudestEl, 1)
        if loudestLine:
            for Idx in range( len( columnIdx )):
                loudIdx = SubElement( loudestEl, columnIdx[Idx])
                loudIdx.text = loudestLine[Idx]
                indent(loudIdx, 2)   # loudest template values are level 2
            loudIdx = SubElement( loudestEl, "cover_freq")
            loudIdx.text = template_covering_band(loudestLine, Tspan)[0]
            indent(loudIdx, 2)   # loudest template values are level 2
            loudIdx = SubElement( loudestEl, "cover_band")
            loudIdx.text = template_covering_band(loudestLine, Tspan)[1]
            indent(loudIdx, 2)   # loudest template values are level 2
        SubElement( currentSearchJobEl,"num_templates").text = numTemplates
        indent(loudestEl, 1)
        SubElement( currentSearchJobEl,"num_templates_vetoed").text = str( IFOvetoed )
        indent(loudestEl, 1)
    # Check to see if it's both the last band segment in the job the very last upper limit segment
    # TODO make this and the search band insertion loop a single function(jobNum, sorted_Bands, loudestLine, outputTree)
    if ( ulNum == sorted_ulBands[-1][2] and searchBand == sorted_searchBands[-1]):
        # Add to upper limits XML tree
        for ulElement in upper_limit_root:
            for ulSubElement in ulElement.iter('job'):
                if ulSubElement.text == str( ulNum ):
                    loudestEl = SubElement( ulElement,"loudest_nonvetoed_template")
                    indent(loudestEl, 1)
                    SubElement( ulElement,"num_templates").text = numTemplates
                    indent(loudestEl, 1)
                    SubElement( ulElement,"num_templates_vetoed").text = str( IFOvetoed )
                    indent(loudestEl, 1)
        if loudestLine_ul:
            for Idx in range( len(columnIdx )):
                loudIdx = SubElement( loudestEl, columnIdx[Idx])
                loudIdx.text = loudestLine_ul[Idx]
                indent(loudIdx, 2)   # loudest template values are level 2
            loudIdx = SubElement( loudestEl, "cover_freq")
            loudIdx.text = template_covering_band(loudestLine_ul, Tspan)[0]
            indent(loudIdx, 2)   # loudest template values are level 2
            loudIdx = SubElement( loudestEl, "cover_band")
            loudIdx.text = template_covering_band(loudestLine_ul, Tspan)[1]
            indent(loudIdx, 2)   # loudest template values are level 2
        else:
            # If whole UL band is vetoed...
            loudIdx = SubElement( loudestEl, "twoF")
            loudIdx.text = "0.0"
            loudIdx.comment = "Whole UL band is vetoed"
            indent(loudIdx, 2)   # loudest template values are level 2
    # Check if it's a regular last segment in an upper limit band
    elif ulNum < sorted( ul_interval[sorted_searchBands[ segmentCounter + 1 ][0]] )[0][2]:
        # Add to upper limits XML tree
        for ulElement in upper_limit_root:
            for ulSubElement in ulElement.iter('job'):
                if ulSubElement.text == str( ulNum ):
                    loudestEl = SubElement( ulElement,"loudest_nonvetoed_template")
                    indent(loudestEl, 1)
                    SubElement( ulElement,"num_templates").text = numTemplates
                    indent(loudestEl, 1)
                    SubElement( ulElement,"num_templates_vetoed").text = str( IFOvetoed )
                    indent(loudestEl, 1)
        if loudestLine_ul:
            for Idx in range( len(columnIdx )):
                loudIdx = SubElement( loudestEl, columnIdx[Idx])
                loudIdx.text = loudestLine_ul[Idx]
                indent(loudIdx, 2)   # loudest template values are level 2
            loudIdx = SubElement( loudestEl, "cover_freq")
            loudIdx.text = template_covering_band(loudestLine_ul, Tspan)[0]
            indent(loudIdx, 2)   # loudest template values are level 2
            loudIdx = SubElement( loudestEl, "cover_band")
            loudIdx.text = template_covering_band(loudestLine_ul, Tspan)[1]
            indent(loudIdx, 2)   # loudest template values are level 2
        else:
            # If whole UL band is vetoed...
            loudIdx = SubElement( loudestEl, "twoF")
            loudIdx.text = "0.0"
            loudIdx.comment = "Whole UL band is vetoed"
            indent(loudIdx, 2)   # loudest template values are level 2
    # Increment at the end of the segment loop
    prev_jobNum = jobNum
    prev_ulNum = ulNum
    segmentCounter += 1

# Write search_bands.xml
indent(search_root)
search_bands_xml = ET.ElementTree(search_root)
#search_bands_xml.write("../../search_bands.xml", xml_declaration=True, encoding='UTF-8', method='html')
search_bands_xml.write("../../search_bands.xml", xml_declaration=True, encoding='UTF-8', method='xml')

# Bzip the search_bands.xml
#search_bands_file = bz2.BZ2File('../../search_bands.xml.bz2', 'wb')
#with open('../../search_bands.xml','r') as searchBandsFile:
#    try:
#        search_bands_file.write([x for x in searchBandsFile])
#    finally:
#        search_bands_file.close()
# TODO This is just a hack, and needs a better (native) BZ2 compression:
os.system("bzip2 -f ../../search_bands.xml")

# Write upper limits XML
indent(upper_limit_root)
upper_limit_bands_xml = ET.ElementTree(upper_limit_root)
upper_limit_bands_xml.write("../../upper_limit_bands.xml", xml_declaration=True, encoding='UTF-8', method='xml' )

# Rewrite veto_bands.xml
# TODO  Merge IFO-vetoed bands with previous veto bands (not strictly necessary---for now)
if len(ifo_v_jobs):   # Append ifo vetoed jobs to vetoed bands file (if they exist)
    veto_bands_xml = ET.ElementTree( veto_root )
    #veto_bands_xml.append( veto_segments )
    veto_bands_xml.write("../../veto_bands.xml", xml_declaration=True, encoding='UTF-8', method='html')
    print("IFO vetoed jobs: " + ifo_v_jobs )

# Write ifo_v_jobs.txt file (will overwrite existing!)
# This is for reference only, as you only need to run this script once
with open("../../ifo_v_jobs.txt",'a') as ifoJobsFile:
    ifoJobsFile.write( ifo_v_jobs )


end_time = time.clock()
print("Total run-time: " + str( end_time - start_time ) + " sec")

#------------------------------------------------------------------------------
#   End of collateSearchResults.py
#------------------------------------------------------------------------------
