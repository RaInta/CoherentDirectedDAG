#!/usr/bin/python

#------------------------------------------------------------------------------
#           Name: readOptimalStretch.py
#         Author: Ra Inta, 20150213
#  Last Modified: 20150213
# This reads an XML file with the information for the optimal SFT stretch used
# in a directed CW search, optimal_sft_stretch.xml
# It will be used to display information in a summary web-page
#------------------------------------------------------------------------------

import xml.etree.ElementTree as ET
import subprocess




############################################################
#1) Read setup, upper limit and veto bands
############################################################

tree = ET.parse( open( "optimal_sft_stretch.xml",'r') )
root = tree.getroot()

start_time = root[1].find("start_time").text
end_time = root[1].find("end_time").text
Tspan = str( float( root[1].find("span_time").text) / (3600*24) )
Tobs = str( float( root[1].find("obs_time").text) / (3600*24) )
Nsfts = root[1].find("num_sfts").text
N_H1 = root[1].find("num_sfts_H1").text
N_L1 = root[1].find("num_sfts_L1").text

# get human versions of GPS time. Note: requires lalapps_tconvert to exist

#proc_start = subprocess.Popen(["/home/ra/master/opt/lscsoft/lalapps/bin/lalapps_tconvert", start_time], stdout=subprocess.PIPE, shell=True)
#proc_end = subprocess.Popen(["lalapps_tconvert", end_time], stdout=subprocess.PIPE, shell=True)
#(Tstart_human, err) = proc_start.communicate()
#(Tend_human, err) = proc_end.communicate()
#
#if err != 0:
#    Tstart_human = ""
#    Tend_human = ""

Tstart_human = subprocess.check_output("lalapps_tconvert " + start_time, shell=True)
Tend_human = subprocess.check_output("lalapps_tconvert " + end_time, shell=True)

######### TEST ###################


print("Start time: "  + start_time + " or :" + Tstart_human)
print("End time: "  + end_time + " or :" + Tend_human)
print("Tspan: "  + Tspan)
print("Tobs: "  + Tobs)
print("Nsfts: "  + Nsfts)
print("Nsfts_H1: "  + N_H1)
print("Nsfts_L1: "  + N_L1)

##################################################

##################################################
#           End of readOptimalStretch.py
##################################################
