#!/usr/bin/python

#------------------------------------------------------------------------------
#           Name: singleJob.py
#         Author: Ra Inta, 20150205
#  Last Modified: 20150309
#This is a follow-up to the lookThresh.py script; it reads the top_jobs.txt list
# and analyses each candidate job for stats etc. A couple of functions are
# re-used from lookThresh.py, so it's imported here.
#------------------------------------------------------------------------------

#import matplotlib as mpl
#mpl.use('Agg')       # This is so we can use matplotlib easily without setting $DISPLAY on remote servers
#from matplotlib import pyplot as plt
import numpy as np
import os
import string
#from lookThresh import CDF_trial, ksDist, prob, getLookThresh
from lookThresh import *



##############################
# Just for testing, take input from command line
#from sys import argv
#singleJobId = int( argv[1] )
################################

#subDir = str( int(singleJobId)/250 )   # Note: int division usd here


def getResultsFile( singleJobId ):
    """docstring for getResultsFile"""
    # Get the results file
    subDir = str( int(singleJobId)/250 )   # Note: int division usd here
    singleFreq = []
    singleTwoF = []
    singleFdot = []
    singleFddot = []
    for lines in open( os.path.join( os.getcwd(), "jobs", "search", subDir, "search_results.txt." + str(singleJobId) ), 'r').readlines():
       if not lines[0] == '%':
           eachLine = string.split(lines)
           singleFreq.append(  float( eachLine[0]  ) )
           singleTwoF.append(  float( eachLine[6]  ) )
           singleFdot.append(  float( eachLine[3]  ) )
           singleFddot.append( float( eachLine[4]  ) )

    return  np.array(singleTwoF), np.array(singleFreq), singleFdot, singleFddot


def getHistgramFile( singleJobId ):
    """docstring for getHistgramFile"""
    # Get the histogram
    subDir = str( int(singleJobId)/250 )   # Note: int division usd here
    xHist = []
    yHist = []
    for lines in open( os.path.join( os.getcwd(), "jobs", "search", subDir, "search_histogram.txt." + str(singleJobId) ), 'r').readlines():
       if not lines[0] == '%':
           eachLine = string.split(lines)
           xHist.append( float( eachLine[0] ) )
           yHist.append( float( eachLine[2] ) )

    return np.array( xHist ), np.array( yHist )




def singleJobThresh( singleTwoF, singleFreq, singleFdot, singleFddot, xHist, yHist ):
    """Takes in a single job index, reads search results files, and
    calculates the twoF threshold for the job. Is called in a loop from
    singleProcessJobs.py"""
    single_bin_width = xHist[1] - xHist[0]
    Ntot_single = np.sum(yHist)
    PDF_empir_single = yHist/Ntot_single
    #CDF_empir_single = np.cumsum( PDF_empir_single * single_bin_width )
    singleLookThresh = getLookThresh(Ntot_single, min2Fthresh, max2Fthresh)
    singleMaxIdx = np.where( singleTwoF == max(singleTwoF) )[0][0]
    singleMax2F = singleTwoF[ singleMaxIdx ]
    singleMaxFreq = singleFreq[ singleMaxIdx ]
    singleMaxFdot = singleFdot[  singleMaxIdx ]
    singleMaxFddot = singleFddot[  singleMaxIdx ]
    return singleLookThresh, singleMax2F, singleMaxFreq, singleMaxFdot, singleMaxFddot




#figDir=os.path.join(os.getcwd(), 'figures')
#if not os.path.isdir( os.path.join(os.getcwd(), 'cleanedResults', "cleaned_candidate.txt." + str(singleJobId) ) ):
#   print("Warning! No cleaned results file cleaned_candidate.txt." + str(singleJobId) + " found. Attempting to run the cleaning utility" )
#   #if not


#############################################################################################


#############################################################################################
# 3) Call it all
#############################################################################################


def singleJobOutputStr( singleJobId ):
    """docstring for singleJobOutputStr"""
    jobOutputStr = ""
    singleTwoF, singleFreq, singleFdot, singleFddot = getResultsFile( singleJobId )
    xHist, yHist = getHistgramFile( singleJobId )
    singleLookThresh, singleMax2F, singleMaxFreq, singleMaxFdot, singleMaxFddot = singleJobThresh( singleTwoF, singleFreq, singleFdot, singleFddot, xHist, yHist )
    jobOutputStr +=  "Maximum 2F for this job: " + str(singleMax2F) + "\n"
    jobOutputStr +=  "Freq: " + str(singleMaxFreq) + " Hz, "
    jobOutputStr +=  "f1dot: " + str(singleMaxFdot) + " Hz/s, "
    jobOutputStr +=  "f2dot: " + str(singleMaxFddot) + " Hz/s^2\n"
    jobOutputStr +=  "Threshold for this job (95% C.I.): " + str(singleLookThresh) + "\n"
    return jobOutputStr


#############################################################################################


#############################################################################################
# 4) Output values
#############################################################################################


#print( "Processing job number "  + str(singleJobId) )
#print( "Loudest 2F: " + str( singleMax2F ) )
#print( "Frequency: " + str( singleMaxFreq ) + "Hz" )
#print( "Expected 2F at (95% C.I.): " + str( singleLookThresh ) )
##print( "Probability of loudest 2F being in noise: " + str( singleProb ) )


#########  end of singleJobThresh function            #######################################

#############################################################################################
# 5) Plot everything
#############################################################################################


def single2FPlot( singleJobId ):
    """docstring for single2FPlot"""
    singleTwoF, singleFreq, singleFdot, singleFddot = getResultsFile( singleJobId )
    xHist, yHist = getHistgramFile( singleJobId )
    singleLookThresh, singleMax2F, singleMaxFreq, singleMaxFdot, singleMaxFddot = singleJobThresh( singleTwoF, singleFreq, singleFdot, singleFddot, xHist, yHist )
    #############################################################################################
    # Plot loudest 2F per job vs freq.
    #############################################################################################
    plt.figure(7)
    plt.plot(singleFreq, singleTwoF, "-bo", label="2F distribution")
    plt.plot(singleFreq, [lookThresh for x in range(len(singleFreq))], "-g", label="2F theshold (whole search)")
    plt.plot(singleFreq, [singleLookThresh for x in range(len(singleFreq))], "-r", label="2F theshold (this job)")
    plt.axis([min(singleFreq), max(singleFreq), 0.9*min(singleTwoF), 1.1*max(singleTwoF)])
    xForPlot = np.linspace(min(singleFreq), max(singleFreq), 5)  # Make 5 marks on abscissa and ordinate
    yForPlot = np.linspace(0.9*min(singleTwoF) , 1.1*max(singleTwoF), 5)
    x2DecPlcs = ['%.2f' % a for a in xForPlot ]
    y2DecPlcs = ['%.2f' % a for a in yForPlot ]
    plt.xticks(xForPlot, x2DecPlcs)
    plt.yticks(yForPlot, y2DecPlcs)
    plt.title("$2\mathcal{F}$ distribution, job " + str( singleJobId  ) )
    plt.xlabel("Frequency (Hz)")
    plt.ylabel("$2\mathcal{F}$ ")
    #legend = plt.legend(loc='best', shadow=True)
    #frame = legend.get_frame()   # Some probably overly sophisticated additions to the legend
    #frame.set_facecolor('0.90')
    single2FPlotName =  os.path.join(figDir, "twoF_vs_freq_job_" + str(singleJobId) + ".png" )
    plt.savefig( single2FPlotName ,
                dpi=None, facecolor='w', edgecolor='w', orientation='portrait',
                papertype=None, format="png", transparent= False, bbox_inches=None,
                pad_inches=0.5, frameon=None)
    return str( single2FPlotName )



def singleHistPlot( singleJobId ):
    """docstring for singleHistPlot"""
    xHist, yHist = getHistgramFile( singleJobId )
    plt.figure(8)
    plt.semilogy(xHist, yHist, "-bo", label="Data")
    plt.semilogy(xHist, yHist, "-g", label="95% C.I., whole search")
    plt.semilogy(xHist, yHist, "-r", label="95% C.I., this job")
    singleHistPlotName =  os.path.join(figDir, "histogram_job_" + str(singleJobId) + ".png" )
    plt.savefig( singleHistPlotName ,
                dpi=None, facecolor='w', edgecolor='w', orientation='portrait',
                papertype=None, format="png", transparent= False, bbox_inches=None,
                pad_inches=0.5, frameon=None)
    return str( singleHistPlotName )




#############################################################################################
#            End of singleJob.py
#############################################################################################
