#!/bin/bash

# This is a script to benchmark timing of a Python version of the search results collation script used in the
# 'PostCasA' pipeline. The former is called collateSearchResults.py, while the latter is CollateSearchResults.pl 
# Note I have slightly modified the Perl script to print out how long it took to complete its execution.
#
# Created: 7 December 2015, Ra Inta
# Last modified: 20151207, R.I. 

SCRIPTS=$(dirname $0) # Assumes this script is in the same location as the two collation scripts
COLL_PY=${SCRIPTS}/collateSearchResults.py
COLL_PL=${SCRIPTS}/CollateSearchResults.pl
TIMING_FILE="$(pwd)/collateTimingResults.txt"

echo -e "Python version:\n" >> ${TIMING_FILE}
$COLL_PY >> ${TIMING_FILE}
echo -e "\n\n\nPerl version:\n" >> ${TIMING_FILE}
cd jobs/search/
$COLL_PL >> ${TIMING_FILE}
cd -
