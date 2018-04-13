#!/usr/bin/python

# ------------------------------------------------------------------------------
#            Name: createHTML.py
#          Author: Ra Inta, 20150205
#   Last Modified: 20150205
#  This creates an HTML document of all the figures and main results for the
#   overall search, as well as the top jobs list.
#  This is also an experiment with Django, the Python-based web application
#  builder. This is a problem because Django is not offered as a standard feature
#  on most HPC clusters.
# ------------------------------------------------------------------------------

from django.template import Template, Context
from django.conf import settings
settings.configure()
import string
from plotUpperLimits import *
from readOptimalStretch import *
from singleJob import *


########################################
# Give topJobsList for testing only:
#topJobsList = [1, 2, 3]
########################################

jobId = []

for lines in open("top_jobs.txt", 'r').readlines():
    if not lines[0] == '%':
        eachLine = string.split(lines)
        jobId.append(eachLine[0])

if len(jobId) > 10:
    jobIdTail = jobId[10:]
    jobId = jobId[0:9]
else:
    jobIdTail = []


def jobOut( jobId ):
    """docstring for jobOut"""
    jobOut.jobNumber =  str( jobId )
    jobOut.outputStr = singleJobOutputStr( jobId )
    jobOut.twoFPlot = single2FPlot( jobId )
    jobOut.histPlot = singleHistPlot( jobId )
    return jobOut


#def jobOut( jobId ):
#    """docstring for jobOut"""
#    jobOut = ""
#    for singleJobId in jobId:
#        jobOut.jobNumber =  str(singlejobId)
#        jobOut.outputStr = singleJobOutputStr( singlejobId )
#        jobOut.twoFPlot = single2FPlot( singlejobId )
#        jobOut.histPlot = singleHistPlot( singlejobId )
#    return jobOut

####
#jobHeadOut = jobOut( jobId )
#jobTailOut = jobOut( jobIdTail )

#jobHeadStr = []
#jobTailStr = []
#
#jobHeadStr = [ jobHeadStr.append( singleJobOutputStr( singlejobId ) ) for singleJobId in jobId ]
#jobTailStr = [ jobTailStr.append( singleJobOutputStr( singlejobId ) ) for singleJobId in jobIdTail ]

main_template = """
<html>
    <head>
        <title>Results from search {{ title }}</title>
    </head>
<body>
        <h1>Results from search {{ title }}</h1>
    <hr>

    Overall results for search for {{ mystring }}.
    <br><br>

<hr>
<h3>Astrophysical parameters</h3>
<br>

<table style="width:100%" border="1">
  <tr>
    <td>Right ascension</td>
    <td>Declination</td>
    <td>Distance (kpc)</td>
    <td>Spin-down age (kyr)</td>
    <td>Age/spin-based upper limit</td>
  </tr>
  <tr>
    <td>{{ rightAscension }}</td>
    <td>{{ declination }}</td>
    <td>{{ distance }}</td>
    <td>{{ tau }}</td>
    <td>{{ h0_age }}</td>
  </tr>
</table>

<br>

<hr>
<h3>Search preliminaries</h3>
<br>

<table style="width:100%" border="1">
  <tr>
    <td colspan="7"><center>Optimal SFT stretch</center></td>
  </tr>
  <tr>
    <td>Start time stretch</td>
    <td>End time stretch</td>
    <td>Timespan (days)</td>
    <td>Coherence time (days)</td>
    <td>Total SFTs</td>
    <td>N_SFTs (H1)</td>
    <td>N_SFTs (L1)</td>
  </tr>
  <tr>
    <td>{{ start_time }} ({{ Tstart_human }}) </td>
    <td>{{ end_time }} ({{ Tend_human }}) </td>
    <td>{{ Tspan }}</td>
    <td>{{ Tobs }}</td>
    <td>{{ Nsfts }}</td>
    <td>{{ N_H1 }}</td>
    <td>{{ N_L1 }}</td>
  </tr>
</table>

<hr>
<h3>Results</h3>
<br>

<table style="width:100%">
  <tr>
    <td><img width=500px src="./figures/twoF_vs_freq.png" alt="Loudest 2F per
    job, whole search"></td>
    <td><img width=500px src="./figures/PDF_CDF.png" alt="Empirical and expected
    PDF and CDF, whole search"></td>
    <td><img width=500px src="./figures/Neff_graph.png" alt="Kolmogorov-Smirnoff
    distance to determine effective number of templates"></td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
  </tr>
</table>
    <hr>
    <h3>Results for loudest candidate jobs</h3>
    {% block body_block %}
            Job number: {{ singleJobOut.jobNumber }}
            <br>
            {{ singleJobOut.outputStr  }}
            <table style="width:100%" border="1">
            <tr>
            <td>2F vs frequency</td>
            <td>Log histogram</td>
            </tr>
            <tr>
            <td><img width=500px src="
            {{ singleJobOut.twoFPlot  }}
            " ></td>
            <td><img width=500px src="
            {{ singleJobOut.histPlot  }}
            " ></td>
            </tr>
            </table>
            <hr>
    {% endblock %}
    <h3>Upper limits</h3>
    <img width=550px src="./figures/upper_limit_plot.png" alt="Search upper
    limits">
</body>
</html>
"""


# Hopefully just useless junk to delete...if the above doesn't work
# try this:
#
#    {% block body_block %}
#        {% for singleJobId in jobId %}
#        Job number: {{ singleJobId  }}
#        {{ jobHeadStr[jobId) }}
#        <hr>
#        {% endfor %}
#    {% endblock %}


targetName = "G007+003"
someResults = "Some Really Amazing Results"

singlesText = []

#for jobsIdx in topJobsList:
#    singlesText.append(str(jobsIdx) )




t = Template( main_template )
c = Context({"title": targetName,
             "mystring": someResults,
             "singlesText": singlesText,
             "rightAscension": rightAscension,
             "declination" : declination,
             "tau" : tau,
             "distance" : distance,
             "h0_age" : h0_age,
             "start_time" : start_time,
             "Tstart_human" : Tstart_human,
             "end_time" : end_time,
             "Tend_human" : Tend_human,
             "Tspan" : Tspan,
             "Tobs" : Tobs,
             "Nsfts" : Nsfts,
             "N_H1" : N_H1,
             "N_L1" : N_L1,
             "singleJobOut": jobOut(22)
             })

# Use this to check output
#print t.render(c)

output_file = open('search_summary_' + str( targetName  ) + '.html','w')
output_file.write( t.render(c) )
output_file.close()

##############################
#    end of  createHTML.py
##############################
