#!/bin/bash

BASE_DIR=$(pwd)
DAG_DIR=${BASE_DIR}/DAG

SCRIPTS=$(dirname $0)

# Define DAG file
SUB_DAG2="${BASE_DIR}/search.dag"

# Get search job throttle, after checking to see if the file was properly
# written. If not, then ask for user input
MAX_SRCH_FILE="${BASE_DIR}/jobs/search/MAX_SRCH_JOBS.txt"
if [[ -s ${MAX_SRCH_FILE} ]]; then
   MAX_SRCH_JOBS=$(cat ${MAX_SRCH_FILE})
else
   read -p "Warning! MAX_SRCH_JOBS.txt file not found. Please enter the maximum number of search jobs to run simultaneously\n"
   MAX_SRCH_JOBS=${REPLY}
fi

# Get total number of search jobs, after checking to see if the file was properly
# written. If not, then ask for user input
TOTAL_JOBS_FILE="${BASE_DIR}/jobs/search/total_job_number.txt"
if [[ -s ${TOTAL_JOBS_FILE} ]]; then
   TOTAL_JOBS=$(cat ${TOTAL_JOBS_FILE})
else
   read -p "Warning! total_job_number.txt file not found. Please enter the total number of search jobs (if known)\n"
   if [[ $REPLY == "" ]]; then
      echo "Invalid input! Exiting now."
      exit 1
   fi
   TOTAL_JOBS=${REPLY}
fi

# Ashik's kludge to find the number of search jobs
JOBS_PER_FOLDER=250

#NUMBER_OF_FOLDERS=$(ls -1 ${BASE_DIR}/jobs/search | wc -l)
#FILES_IN_LAST_FOLDER=$(ls -1 ${BASE_DIR}/jobs/search/$(( ${NUMBER_OF_FOLDERS} -1 ))| grep search.sub.* | wc -l)
#TOTAL=$(((${NUMBER_OF_FOLDERS}-1)*${JOBS_PER_FOLDER}+${FILES_IN_LAST_FOLDER}))
#
#START=0
#END=${TOTAL}

# Make the new file
JOB_ARRAY=()
CAT_ARRAY=()

#for (( k=0; k<${NUMBER_OF_FOLDERS}; k++ )); do
#   for (( i=${START}; i<${JOBS_PER_FOLDER}; i++ )); do
#      JOB_NUM="$(( ${i}+${JOBS_PER_FOLDER}*${k} ))"
#      JOB_ID="Step12_${JOB_NUM}" 
#      echo -e "JOB ${JOB_ID} search.sub.${JOB_NUM} DIR ${BASE_DIR}/jobs/search/${k}"  >> ${SUB_DAG2}
#      echo -e "RETRY ${JOB_ID} 50"  >> ${SUB_DAG2}
#      JOB_ARRAY+=("${JOB_ID} ")
#      CAT_ARRAY+=("\nCATEGORY ${JOB_ID} SearchJobs")
#   done
#done
#
#TEMP=$((${NUMBER_OF_FOLDERS}-1))*${JOBS_PER_FOLDER}
#
#for (( i=${TEMP}; i<$(( ${TEMP}+${FILES_IN_LAST_FOLDER} )); i++ )); do
#   JOB_NUM="${i}"
#   JOB_ID="Step12_${JOB_NUM}" 
#   echo -e "JOB ${JOB_ID} search.sub.${JOB_NUM} DIR ${BASE_DIR}/jobs/search/$((k+1))"  >> ${SUB_DAG2}
#   echo -e "RETRY ${JOB_ID} 50"  >> ${SUB_DAG2}
#   JOB_ARRAY+=("${JOB_ID} ")
#   CAT_ARRAY+=("\nCATEGORY ${JOB_ID} SearchJobs")
#done


for (( i=0; i<${TOTAL_JOBS}; i++ )); do
   JOB_ID="Step12_${i}"
   SUBDIR=$((i/${JOBS_PER_FOLDER}))
   echo -e "JOB ${JOB_ID} search.sub.${i} DIR ${BASE_DIR}/jobs/search/${SUBDIR}"  >> ${SUB_DAG2}
   echo -e "RETRY ${JOB_ID} 50"  >> ${SUB_DAG2}
   JOB_ARRAY+=("${JOB_ID} ")
   CAT_ARRAY+=("\nCATEGORY ${JOB_ID} SearchJobs")
done

/bin/cat <<EOM >>${SUB_DAG2}
JOB Step13 compute_full_psd.sub DIR ${BASE_DIR}/jobs/full_psd
RETRY Step13 5
SCRIPT PRE Step13 ${DAG_DIR}/PreScriptForStep13.sh 

JOB Step14a collate_search_results.sub DIR ${BASE_DIR}/jobs/search
RETRY Step14a 5
SCRIPT PRE Step14a ${DAG_DIR}/PreScriptForStep14.sh 

JOB Step14b collate_search_results.sub DIR ${BASE_DIR}/jobs/search
RETRY Step14b 5
SCRIPT PRE Step14b ${DAG_DIR}/PreScriptForStep14.sh 

PARENT ${JOB_ARRAY[*]} CHILD Step13
PARENT Step13 CHILD Step14a
PARENT Step14a CHILD Step14b

EOM


echo -e ${CAT_ARRAY[*]} >> ${SUB_DAG2}
echo -e "\nMAXJOBS SearchJobs ${MAX_SRCH_JOBS}" >> ${SUB_DAG2}


