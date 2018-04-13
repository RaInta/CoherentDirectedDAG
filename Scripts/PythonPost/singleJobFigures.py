#!/usr/bin/python


#------------------------------------------------------------------------------
#           Name: singleJobFigures.py
#         Author: Ra Inta, 20150310
#  Last Modified: 20150310
# This produces figures from a single job. It calls singleJob.py and
# lookThresh.py
# (via singleJob.py)
#------------------------------------------------------------------------------

#from lookThresh import CDF_trial, ksDist, prob, getLookThresh
from lookThresh import *
from singleJob import singleJobOutputStr, single2FPlot, singleHistPlot


##############################
# Take input from command line
from sys import argv
singleJobId = int( argv[1] )
################################


print singleJobOutputStr( singleJobId )
print single2FPlot( singleJobId )
print singleHistPlot( singleJobId )


########################################
###  End of  singleJobFigures.py  #####
########################################
