#!/bin/bash

BASE_DIR=$(pwd)
DAG_DIR=${BASE_DIR}/DAG

SCRIPTS=$(dirname $0)

# May change TARGET_DIR in future
TARGET_DIR=${BASE_DIR}
SUB_DAG4="${TARGET_DIR}/injections.dag"

# Throttle for maximum number of UL jobs to run simultaneously
MAX_UL_JOBS=10
INJ_PER_SUBJOB=250
#JOBS_PER_UL_BAND=24


# Count the number of folders in the  directory
#NUM_OF_FOLDERS=$(find ${BASE_DIR}/jobs/upper_limit  -maxdepth 1 -type d -print | wc -l)
#echo "Number of folders: $NUM_OF_FOLDERS"

# Read from search_setup.xml and do some floating point division
# to get NUM_UL_JOBS

read_dom () {
    local IFS=\>
    read -d \< ENTITY CONTENT
    local ret=$?
    TAG_NAME=${ENTITY%% *}
    ATTRIBUTES=${ENTITY#* }
    return $ret
}


BAND=()

while read_dom; do
   if [[ $TAG_NAME = "band" ]]; then
      BAND+=("${CONTENT} ")
   elif [[ $TAG_NAME = "num_injections" ]]; then
      NUM_INJECTIONS=("${CONTENT} ")
   fi
done < search_setup.xml

SEARCH_BAND=${BAND[0]}
UL_BAND=${BAND[1]}

JOBS_PER_UL_BAND=${NUM_INJECTIONS}/${INJ_PER_SUBJOB}


# Exploit AWK's ability to do 'useful' division
NUM_UL_JOBS=`echo "${SEARCH_BAND} ${UL_BAND}" | awk '{printf "%d", $1/$2}'`
#echo ${NUM_UL_JOBS}

JOB_ARRAY=()
CAT_ARRAY=()

for (( i=0; i<${NUM_UL_JOBS}; i++ )); do
   if [ -d ${BASE_DIR}/jobs/upper_limit/${i} ]; then
      for (( k=0; k<${JOBS_PER_UL_BAND}; k++ )); do
         JOB_ID="step16_${i}_${k}"
         echo "JOB ${JOB_ID} upper_limit_injections.sub.${i}.${k} DIR ${BASE_DIR}/jobs/upper_limit/${i}"  >> ${SUB_DAG4}
         echo "RETRY ${JOB_ID} 5"  >> ${SUB_DAG4}
         JOB_ARRAY+=("${JOB_ID} ")
         CAT_ARRAY+=("\nCATEGORY ${JOB_ID} InjectionJobs")
      done
   else
      echo "Warning! ${BASE_DIR}/jobs/upper_limit/${i} does not exist" 
   fi
done

/bin/cat <<EOM >>${SUB_DAG4}

JOB wait wait.sub DIR ${DAG_DIR}
RETRY wait 5
SCRIPT POST wait ${DAG_DIR}/PostScriptForStep17.sh

PARENT ${JOB_ARRAY[*]} CHILD wait 

EOM

echo -e ${CAT_ARRAY[*]} >> ${SUB_DAG4}
echo -e "\nMAXJOBS InjectionJobs ${MAX_UL_JOBS}" >> ${SUB_DAG4} 
