#!/bin/bash

# This is a temporary fix to the search.log files to output total template count and EOF information.
# This is because the current version of lalapps_ComputeFStatistic_v2 doesn't seem to easily give verbose output
#
# Created: 22 January 2015, Ra Inta
# Last modified: 20150515, R.I.


JOBS_PER_SUBFOLDER=250
SEARCH_FOLDER="jobs/search"


for i in $(ls ${SEARCH_FOLDER}/*/search_histogram.txt.*); do
   FILE_IDX=`expr match $i '.*\.\([0-9]*\)'`
   NUM_TEMPL=$(awk '!/^%/{ sum += $3 } END { print sum }' ${i});
   OUT_FILE=${SEARCH_FOLDER}/$((${FILE_IDX}/${JOBS_PER_SUBFOLDER}))/search.log.${FILE_IDX} 
   echo -e "[debug]: Counting spindown lattice templates ... ${NUM_TEMPL}\n[debug]: Freeing Doppler grid ... done." > ${OUT_FILE}; 
   echo "processing file: $i, file idx: ${FILE_IDX}, num templ: ${NUM_TEMPL}, to ${OUT_FILE}"
done
