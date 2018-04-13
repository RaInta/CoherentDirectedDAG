#!/usr/bin/python

#------------------------------------------------------------------------------
#           Name: plotUpperLimits.py
#         Author: Ra Inta, 20150212
#  Last Modified: 20150212
#This is to read upper limits files and plot them so another Python script
# createHTML.py, can display them at the end of a search summary.
# If they do not exist, it should gracefully quit, giving a placeholder so
# the parent script doesn't fail miserably.
#------------------------------------------------------------------------------

import numpy as np
import matplotlib as mpl
mpl.use('Agg')       # This is so we can use matplotlib easily without setting $DISPLAY on remote servers
from matplotlib import pyplot as plt
import xml.etree.ElementTree as ET
from math import pow
import os




############################################################
#1) Read setup, upper limit and veto bands
############################################################

tree = ET.parse( open( "search_setup.xml",'r') )
root = tree.getroot()


#targetName = root[0].find("target").text
rightAscension = root[0].find("right_ascension").text
declination = root[0].find("declination").text
tau = float( root[0].find('spindown_age').text ) / (365.25*24*3600)
distance = float( root[0].find('distance').text ) / 3.08567758e19
Izz = float( root[0].find('moment_of_inertia').text )

print("Right Ascension: " + rightAscension )
print("Declination: " + declination )

def h0_age( tau, distance, Izz ):
    """calculates the spin-down based upper limit, h0_age, from the
    supernova remnant's
    age, distance and estimated moment of inertia"""
    return 1.2e-24 * ( 3.4 / distance ) * pow( ( 300.0 / tau ) * ( Izz / 1.0e38) , 0.5)

h0_age = h0_age( tau, distance, Izz )

# Test to see if upper limits exist yet; fail gracefully and make a placeholder
# if not.
if os.path.isfile("upper_limit_bands.xml"):
   tree = ET.parse( open( "upper_limit_bands.xml",'r') )
   root = tree.getroot()

   band_freq = []
   band_width = [] #Usually constant, but we'll collect it up anyway
   h0_ul = []

   for band in root.iter('upper_limit_band'):
       h0_ul.append( float( band.find('upper_limit_h0').text ) )
       band_freq.append( float( band.find('freq').text ) )
       band_width.append( float( band.find('band').text ) )

   h0_ul = np.array( h0_ul  )
   band_freq = np.array( band_freq  )
   band_width = np.array( band_width  )


   # Get veto bands
   tree = ET.parse( open( "veto_bands.xml",'r') )
   root = tree.getroot()

   veto_freq = []
   veto_width = [] #Usually constant, but we'll collect it up anyway

   for band in root.iter('veto_band'):
       veto_freq.append( float( band.find('freq').text ) )
       veto_width.append( float( band.find('band').text ) )


   veto_freq = np.array( veto_freq  )
   veto_width = np.array( veto_width  )


   #############################################################################################
   # Plot upper limits
   #############################################################################################

   figDir=os.path.join(os.getcwd(), 'figures')
   if not os.path.isdir(figDir):
       os.mkdir(figDir)

   plt.figure(57)

   plt.plot(band_freq + 0.5*band_width, h0_ul, "-ko", label="Upper limits")
   plt.plot(band_freq + 0.5*band_width, [h0_age for x in band_freq], "-b", label="Age-based upper limit")

   yPlotMax = 1.1*np.max([ max(h0_ul), h0_age ] )

   plt.plot(veto_freq, [yPlotMax for x in veto_freq], "-or", label="Vetoed bands")

   plt.axis([min(band_freq), max(band_freq), 0.9*np.min([ min(h0_ul), h0_age ]), yPlotMax ])


   xForPlot = np.linspace(min(band_freq), max(band_freq+band_width), 5)  # Make 5 marks on abscissa and ordinate
   yForPlot = np.linspace(0.9*np.min([ min(h0_ul), h0_age ]) , 1.1*np.max([ max(h0_ul), h0_age ] ), 5)
   x2DecPlcs = ['%.2f' % a for a in xForPlot ]
   y2DecPlcs = ['%.3g' % a for a in yForPlot ]
   plt.xticks(xForPlot, x2DecPlcs)
   plt.yticks(yForPlot, y2DecPlcs)

   plt.title("Estimated upper limits")
   plt.xlabel("Frequency (Hz)")
   plt.ylabel("$h_0$")

   legend = plt.legend(loc='best', shadow=True)
   frame = legend.get_frame()   # Some probably overly sophisticated additions to the legend
   frame.set_facecolor('0.90')

   #plt.draw()
   plt.savefig( os.path.join(figDir, "upper_limit_plot.png" ), dpi=None, facecolor='w', edgecolor='w', orientation='portrait', papertype=None, format="png", transparent=False, bbox_inches="tight", pad_inches=0.1, frameon=None)


############################################################
#  End of lplotUpperLimits.py
############################################################
