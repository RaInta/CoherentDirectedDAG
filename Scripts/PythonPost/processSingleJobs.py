#!/usr/bin/python

#------------------------------------------------------------------------------
#           Name: processSingleJobs.py
#         Author: Ra Inta, 20150205
#  Last Modified: 20150218
#This is a follow-up to the lookThresh.py script; it reads the top_jobs.txt list
# and analyses each candidate job for stats etc. A couple of functions are
# re-used from lookThresh.py, so it's imported here.
#------------------------------------------------------------------------------

import os
import string
from lookThresh import *
from singleJob import *


jobId = []

for lines in open("top_jobs.txt", 'r').readlines():
    if not lines[0] == '%':
        eachLine = string.split(lines)
        jobId.append(eachLine[0])

# Checks that jobId is less than ten candidates, otherwise put rest at the
# back, after upper limits plot

if len(jobId) > 10:
    jobIdTail = jobId[10:]
    jobId = jobId[0:9]

def jobOut( jobId ):
    """docstring for jobOut"""
    jobOut = ""
    for singleJobId in jobId:
        jobOut.append( "Job number: " + str(singleJobId) + "\n" )
        jobOut.append( singleJobOutputStr( singleJobId ) )
        jobOut.append( "" )
        jobOut.append( single2FPlot( singleJobId )

    return jobOut

jobHeadOut = jobOut( jobId )
jobTailOut = jobOut( jobIdTail )

#------------------------------------------------------------------------------
#           End of processSingleJobs.py
#------------------------------------------------------------------------------

