#!/bin/bash

############## Overview for set_up_search_DAG.sh #################
#
# To run a search:
# 1) Set desired SFT type, GPS times etc. in this script (below)
# 2) Run this script (which should be located in a directory containing 
# your other scripts) from either a base directory, or add a target name
# as an optional command-line argument
# 3) Submit the master DAG: condor_submit_dag master.dag
#
#######################################################################
# 
# How the DAG is structured
#
# MASTER: master.dag , contains:
# HEAD_DAG1: setup_and_search.dag , HEAD_DAG2: upper_limit.dag 
#
# HEAD_DAG1 contains:
# SUB_DAG1 setup.dag , SUB_DAG2 search.dag
# 
# HEAD_DAG2 contains:
# SUB_DAG3 upper_limit.dag , SUB_DAG4 injections.dag
#
# The numbers referred to in DAG Post-/Pre-script titles are from the GUIDE.sh
#  script originating from the (modified) Cas A pipeline.
#
# Note that, because the number of search jobs
# are unknown before beginning the pipeline, the DAG associated with
# it is currently re-written on the fly using the shell script
# rewrite_search_dag.sh . 
#
#######################################################################


BASE_DIR=$(pwd)
SCRIPTS=$(dirname $0)

# Take in optional command line argument as target (useful for looping)
if [ -n "$1" ]; then
   TARGET=$1
   TARGET_DIR=${BASE_DIR}/${TARGET}
   echo -e "Setting up search from ${BASE_DIR} on target ${TARGET}\n"
else
   echo -e "Target is not explicitly set, taking current directory as base directory."
   TARGET=${BASE_DIR}
   TARGET_DIR=${BASE_DIR}
fi

echo -e "Target directory: ${TARGET_DIR}\n"



##################################################################



####### Pick and choose your favourite SFT types and times ########

## MDC SFTs, for testing
#H1TYPE='1_H1_1800SFT_fromCWINJ_TOT_SET2'
#L1TYPE='1_L1_1800SFT_fromCWINJ_TOT_SET2'

########### S6 SFTs ##############################  
#H1TYPE='1_H1_1800SFT_allS6VSR2VSR3'
#L1TYPE='1_L1_1800SFT_allS6VSR2VSR3'

########## O1 SFTs ##############################  
#H1TYPE='1_H1_1800SFT_O1'
#L1TYPE='1_L1_1800SFT_O1'
# First updated calibration of O1 SFTs
H1TYPE='1_H1_1800SFT_O1_C01'
L1TYPE='1_L1_1800SFT_O1_C01'

########## GPS start and stop times #############  
#GPS0='931000000'
#GPS1='972000000'
#GPS0='951534120'
#GPS1='971619922'
#GPS0='954403520'
#GPS1='971619922'

# Encompassing all of O1 (112662360046 - 1136649617)
GPS0='1126623600'
GPS1='1136649700'

JOB_HOURS='4'

cat <<EOF
********************************************************************
*** H1_SFTs: ${H1TYPE} ********************************
*** L1_SFTs: ${L1TYPE} ********************************
********************************************************************
*** GPS_START: ${GPS0} ***************************
*** GPS_END: ${GPS1} *****************************
********************************************************************
*** Each search job is set to run ${JOB_HOURS} hours *************
********************************************************************
EOF

##################################################################
###### For LDG accounting purposes ###############################
###### Enter your LIGO (albert.einstein) username ################
###### And check if dev/prod         #############################

# OLD TAGS:
#ACCOUNT_GROUP=ligo.dev.o1.cw.coherentsupnovrem
#ACCOUNT_GROUP=ligo.prod.o1.cw.coherentsupnovrem
# For ER7 Spotlight outlier work:
#ACCOUNT_GROUP=ligo.prod.s6.cw.directedisolated.coherent


# Cas A only O1 tags:
#ACCOUNT_GROUP=ligo.dev.o1.cw.directedisolated.coherent
#ACCOUNT_GROUP=ligo.prod.o1.cw.directedisolated.coherent

# All others, O1 tags:
#ACCOUNT_GROUP=ligo.dev.o1.cw.directedisolatedother.coherent
ACCOUNT_GROUP=ligo.prod.o1.cw.directedisolatedother.coherent



#read -p 'For LDG accounting purposes, please enter your LIGO (albert.einstein) username: '
#if [[ "${REPLY}" == *.* ]]; then
#    ACCOUNT_USER=${REPLY}
#else
#   echo -e "\aInvalid username." 
#   read -p "Please enter your albert.einstein username for LDG bean-counting purposes: "
#   if [[ "${REPLY}" == *.* ]]; then
#      ACCOUNT_USER=${REPLY}
#   else
#      echo -e "\aOK smart-ass, you obviously want to abort this script.\nAborting..."
#      exit 74
#   fi
#fi

if [ $USER == "ra" ]; then 
   ACCOUNT_USER=ra.inta
else
   read -p 'For accounting purposes, please enter your albert.einstein LSC username: '
   ACCOUNT_USER=${REPLY}
fi

echo "Using account username: ${ACCOUNT_USER}"

##################################################################


##################################################################
########### Most of the variables in this section #################
########### shouldn't  need to change unless you're #################
########### developing  #############################################

######### Number of jobs to run to get SFT info
NUM_SFT_INFO_JOBS=20

######### Max number of search and UL jobs to run simultaneously
# Pro tip: this might really depend on your current user priority

MAX_SRCH_JOBS=1000

MAX_UL_JOBS=200


######### Number of injection jobs per sub-band
INJ_PER_SUBJOB=250



####################################################################
# Read from search_setup.xml and do some floating point division
# to get NUM_UL_JOBS and JOBS_PER_UL_BAND
####################################################################

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
done < ${TARGET_DIR}/search_setup.xml

SEARCH_BAND=${BAND[0]}
UL_BAND=${BAND[1]}

JOBS_PER_UL_BAND=${NUM_INJECTIONS}/${INJ_PER_SUBJOB}

# Exploit AWK's ability to do 'useful' division
NUM_UL_JOBS=`echo "${SEARCH_BAND} ${UL_BAND}" | awk '{printf "%d", $1/$2}'`
#echo ${NUM_UL_JOBS}

#################################################################



##################################################################
############### Nothing below here requires user input ###########

# Create TARGET_DIR as well as the DAG subdirectory if it doesn't already exist
DAG_DIR=${TARGET_DIR}/DAG
mkdir -p ${DAG_DIR}

######### Invoke script to create local and global directories ####

${SCRIPTS}/MakeGlobalLocalDirs.sh

######## Set up local and global directories if necessary ##########
#
#if [ ! -d "${TARGET_DIR}/global/sfts" ] || [ ! -h "${TARGET_DIR}/global/sfts" ]; then
#   ${SCRIPTS}/SetupDirectories.sh
#fi
#
###################################################################


# DON'T mess with the linebreak or the quotes here
PERL_HEADER='#!/bin/bash
#!/usr/bin/perl' 

ACCOUNT_HEADER=`echo -e "\naccounting_group = ${ACCOUNT_GROUP}\naccounting_group_user = ${ACCOUNT_USER}\n"`
#ACCOUNT_HEADER='printf "\naccounting_group = %s\naccounting_group_user = %s\n"  ${ACCOUNT_GROUP} ${ACCOUNT_USER}'

####### Establish filenames ####################

######### Define names of DAG files #############
MASTER_DAG="${TARGET_DIR}/master.dag"
HEAD_DAG1="${TARGET_DIR}/setup_and_search.dag"
HEAD_DAG2="${TARGET_DIR}/upper_limit_and_injections.dag"

SUB_DAG1="${TARGET_DIR}/setup.dag"
SUB_DAG2="${TARGET_DIR}/search.dag"

SUB_DAG3="${TARGET_DIR}/upper_limit.dag"
SUB_DAG4="${TARGET_DIR}/injections.dag"


######### Define pre/post shell scripts #############
######## PRSn == PRE script for Step n #############
PRS5="${DAG_DIR}/PreScriptForStep5.sh"
PRS7="${DAG_DIR}/PreScriptForStep7.sh"
PRS10="${DAG_DIR}/PreScriptForStep10.sh"
PRS13="${DAG_DIR}/PreScriptForStep13.sh"
PRS14="${DAG_DIR}/PreScriptForStep14.sh"
PRS15="${DAG_DIR}/PreScriptForStep15.sh"

######## POSn == POST script for Step n #############
POS11="${DAG_DIR}/PostScriptForStep11.sh"
POS15="${DAG_DIR}/PostScriptForStep15.sh"
POS17="${DAG_DIR}/PostScriptForStep17.sh"


### This makes Step 11 a Condor job because Step 10 is prone to failure
STEP11="${TARGET_DIR}/jobs/search/create_search_jobs.sub"

######## FIND_SFTS finds SFTS and adds to database ###
FIND_SFTS="${DAG_DIR}/FindSFTs.sh"

######## WAIT just waits for a while ###########
WAIT="${DAG_DIR}/wait.sub"

##################################################################



##################################################################


######### Make .../jobs/ sub-directories  #########################

for i in "templ_dens" "comp_cost" "get_sft_info" "search" "full_psd" "upper_limit" "search_setup" "find_sfts"; do
   mkdir -p ${TARGET_DIR}/jobs/${i}
done

####### Set up template density jobs #############################

if [[ -e ${TARGET_DIR}/search_setup.xml ]]; then
   cd ${TARGET_DIR}/jobs/templ_dens
   perl ${SCRIPTS}/MakeCalcTemplateDensityJobs_new.pl --account-group ${ACCOUNT_GROUP} --account-user ${ACCOUNT_USER}
fi

NUM_TEMPL_JOBS=$(ls -l ${TARGET_DIR}/jobs/templ_dens | grep .sub | wc -l)

##################################################################


######### Export the search job throttling parameter so we can read it later  ###

echo "${MAX_SRCH_JOBS}" > ${TARGET_DIR}/jobs/search/MAX_SRCH_JOBS.txt

##################################################################

######### Write out DAG and associated BASH scripts  #############################

####### master.dag       #########################################

#echo -e ${ACCOUNT_HEADER} >> ${MASTER_DAG}

/bin/cat <<EOM >>${MASTER_DAG}
SUBDAG EXTERNAL HEAD1 ${HEAD_DAG1} 
SUBDAG EXTERNAL HEAD2 ${HEAD_DAG2}  

PARENT HEAD1 CHILD HEAD2

EOM

##### setup_and_search.dag  ######################################
#echo -e ${ACCOUNT_HEADER} >> ${HEAD_DAG1}

/bin/cat <<EOM >>${HEAD_DAG1}
SUBDAG EXTERNAL  SUB1A ${SUB_DAG1}  
SUBDAG EXTERNAL  SUB1B ${SUB_DAG2}   
SCRIPT PRE 	 SUB1B ${SCRIPTS}/rewrite_search_dag.sh

PARENT SUB1A CHILD SUB1B
EOM

########## upper_limit_and_injections.dag #######################################

#echo -e ${ACCOUNT_HEADER} >> ${HEAD_DAG2}

/bin/cat <<EOM >>${HEAD_DAG2}
SUBDAG EXTERNAL  SUB2A ${SUB_DAG3} 
SUBDAG EXTERNAL  SUB2B ${SUB_DAG4} 

PARENT SUB2A CHILD SUB2B
EOM

######## setup.dag ###############################################
# This is what's called in SUB_DAG1 (setup.dag) 

#echo ${ACCOUNT_HEADER} >> ${SUB_DAG1}


/bin/cat <<EOM >>${SUB_DAG1}
JOB step4 find_sfts.sub DIR ${TARGET_DIR}/jobs/find_sfts
RETRY step4 5
EOM

for (( i=0; i<${NUM_SFT_INFO_JOBS}; i++ )); do
/bin/cat <<EOM >>${SUB_DAG1}
JOB step5_${i} get_sft_info.${i}.sub DIR ${TARGET_DIR}/jobs/get_sft_info
RETRY step5_${i} 30

EOM
done

#echo -n PARENT step5_0 CHILD >>${SUB_DAG1}
#for (( i=1; i<${NUM_SFT_INFO_JOBS}; i++ )); do
#echo -n " "step5_${i} >>${SUB_DAG1}
#done
#echo >>${SUB_DAG1}

/bin/cat <<EOM >>${SUB_DAG1}
SCRIPT PRE step5_0 ${PRS5}

JOB step6 Add_SFT_Info_Database.sub DIR ${TARGET_DIR}/jobs/get_sft_info
RETRY step6 5

EOM

for (( i=0; i<${NUM_SFT_INFO_JOBS}; i++ )); do
ARRAY_STEP5[${i}]=step5_${i}
done


ARRAY_STEP8=()
for (( i=0; i<${NUM_TEMPL_JOBS}; i++ )); do
/bin/cat <<EOM >>${SUB_DAG1}
JOB step8_${i} calc_template_density.${i}.sub DIR ${TARGET_DIR}/jobs/templ_dens
RETRY step8_${i} 5

EOM
ARRAY_STEP8+=('step8_'${i}) 
done

/bin/cat <<EOM >>${SUB_DAG1}
SCRIPT PRE step8_0 ${PRS7}

JOB step10 calc_compute_cost.sub DIR ${TARGET_DIR}/jobs/comp_cost
RETRY step10 5
SCRIPT PRE step10 ${PRS10}
JOB step11 create_search_jobs.sub DIR ${TARGET_DIR}/jobs/search
RETRY step11 5


PARENT step4 CHILD ${ARRAY_STEP5[*]} 
PARENT ${ARRAY_STEP5[*]} CHILD step6
PARENT step6 CHILD ${ARRAY_STEP8[*]}
PARENT ${ARRAY_STEP8[*]} CHILD step10
PARENT step10 CHILD step11 
EOM


###### SUB_DAG2 will be rewritten by rewrite_search_dag.sh ###########

touch ${SUB_DAG2}

#echo ${ACCOUNT_HEADER} >> ${SUB_DAG2}


# Read from search_setup.xml and do some floating point division
# to get NUM_UL_JOBS
#SEARCH_BAND=
#UL_BAND=
#NUM_UL_JOBS=`echo "${SEARCH_BAND} ${UL_BAND}" | awk '{printf "%d", $1/$2}'`
#NUM_UL_JOBS=`echo "1 0.5" | awk '{printf "%d", $1/$2}'`

##### SUB_DAG3 (upper_limit.dag)   ###############################

#echo ${ACCOUNT_HEADER} >> ${SUB_DAG3}

for (( i=0; i<${NUM_UL_JOBS}; i++ )); do
/bin/cat <<EOM >>${SUB_DAG3}
JOB step15_${i} upper_limit.${i}.sub DIR ${TARGET_DIR}/jobs/upper_limit
RETRY step15_${i} 5
SCRIPT POST step15_${i} ${POS15}
EOM
done

#for (( i=0; i<${NUM_UL_JOBS}; i++ )); do
#   ARRAY_STEP15[${i}]=step15_${i}
#done

/bin/cat <<EOM >>${SUB_DAG3}

SCRIPT PRE step15_0 ${PRS15}
EOM


####### SUB_DAG4 ################################################  

touch ${SUB_DAG4}

####### SUB_DAG4 ################################################

#echo ${ACCOUNT_HEADER} >> ${SUB_DAG4}

JOB_ARRAY=()
CAT_ARRAY=()

for (( i=0; i<${NUM_UL_JOBS}; i++ )); do
   for (( k=0; k<${JOBS_PER_UL_BAND}; k++ )); do
      JOB_ID="step16_${i}_${k}"
      echo "JOB ${JOB_ID} upper_limit_injections.sub.${i}.${k} DIR ${BASE_DIR}/jobs/upper_limit/${i}"  >> ${SUB_DAG4}
      echo "RETRY ${JOB_ID} 5"  >> ${SUB_DAG4}
      JOB_ARRAY+=("${JOB_ID} ")
      CAT_ARRAY+=("\nCATEGORY ${JOB_ID} InjectionJobs")
   done
done

/bin/cat <<EOM >>${SUB_DAG4}

JOB wait wait.sub DIR ${DAG_DIR}
RETRY wait 5
SCRIPT POST wait ${DAG_DIR}/PostScriptForStep17.sh

PARENT ${JOB_ARRAY[*]} CHILD wait 

EOM

echo -e ${CAT_ARRAY[*]} >> ${SUB_DAG4}
echo -e "\nMAXJOBS InjectionJobs ${MAX_UL_JOBS}" >> ${SUB_DAG4}
#ut PRE/POST scripts  #############################

##PreScriptToStep5
/bin/cat <<EOM >>${PRS5}
${PERL_HEADER}



# If you have a directory containing a dataset you'd like to analyse instead, comment the above and uncomment and modify the following two lines:
#DATA_DIR=/home/ra/searches/ER7/fullER7/global/sfts
#rm -f ${TARGET_DIR}/sft_database.xml.bz2 && ls ${DATA_DIR}/*.sft | ${SCRIPTS}/AddSFTsToDatabase.pl

 
cd ${TARGET_DIR}/jobs/get_sft_info
perl ${SCRIPTS}/MakeGetSFTInfoJobs_new.pl --account-group ${ACCOUNT_GROUP} --account-user ${ACCOUNT_USER}
EOM

#
##PRS7 PreScriptToStep7

/bin/cat <<EOM >>${PRS7}
${PERL_HEADER}

perl ${SCRIPTS}/FindOptimalSFTStretch.pl

#cd ${TARGET_DIR}/jobs/templ_dens
#perl ${SCRIPTS}/MakeCalcTemplateDensityJobs_new.pl --account-group ${ACCOUNT_GROUP} --account-user ${ACCOUNT_USER}
EOM

#
##PRS10="${TARGET_DIR}/PreScriptForStep10.sh"

/bin/cat <<EOM >>${PRS10}
${PERL_HEADER}

cd ${TARGET_DIR}/jobs/templ_dens
perl ${SCRIPTS}/CollateTemplateDensities.pl

cd ${TARGET_DIR}/jobs/comp_cost
perl ${SCRIPTS}/MakeEstimateComputeCost_new.pl --account-group ${ACCOUNT_GROUP} --account-user ${ACCOUNT_USER}
EOM

#
##PreScriptToStep13

/bin/cat <<EOM >>${PRS13}
${PERL_HEADER}

cd ${TARGET_DIR} # Remove the following three lines if CFSv2 verbose output activated 
${SCRIPTS}/FixSearchLogs.sh  
cd -

perl ${SCRIPTS}/ComputeSpectraAndVetoBands.pl

cd ${TARGET_DIR}/jobs/full_psd
perl ${SCRIPTS}/MakeComputeFullPSD_new.pl --account-group ${ACCOUNT_GROUP} --account-user ${ACCOUNT_USER}
EOM


#
##PreScriptToStep14

/bin/cat <<EOM >>${PRS14}
${PERL_HEADER}

perl ${SCRIPTS}/MakeCollateSearchResults_new.pl --account-group ${ACCOUNT_GROUP} --account-user ${ACCOUNT_USER}
EOM

#
##PreScriptForStep15
/bin/cat <<EOM >>${PRS15}
${PERL_HEADER}

cd ${TARGET_DIR}/jobs/upper_limit
perl ${SCRIPTS}/MakeUpperLimitJobs_new.pl --account-group ${ACCOUNT_GROUP} --account-user ${ACCOUNT_USER}
EOM


## STEP 11
/bin/cat <<EOM >>${STEP11}
${ACCOUNT_HEADER}
initialdir = ${TARGET_DIR}/jobs/search 
getenv = true
universe   = vanilla
executable = ${SCRIPTS}/MakeSearchJobs_new.pl 
arguments  = --job-hours ${JOB_HOURS}  --account-group ${ACCOUNT_GROUP} --account-user ${ACCOUNT_USER}
log        = create_search_jobs.log 
output     = create_search_jobs.out
error      = create_search_jobs.err
queue 1
EOM


#
#POS11="${TARGET_DIR}/PostScriptForStep11.sh"
/bin/cat <<EOM >>${POS11}
${PERL_HEADER}

cd ${TARGET_DIR}/jobs/search
perl ${SCRIPTS}/MakeSearchJobs_new.pl --job-hours ${JOB_HOURS} --account-group ${ACCOUNT_GROUP} --account-user ${ACCOUNT_USER} 
EOM

#
## POS15
/bin/cat <<EOM >>${POS15}
#!/bin/bash

echo "This is a test, we'll probably get rid of this step" 
EOM

#
##POS17
/bin/cat <<EOM >>${POS17}
${PERL_HEADER}

cd ${TARGET_DIR}/jobs/upper_limit
perl ${SCRIPTS}/CollateUpperLimits.pl
EOM


#
## FIND_SFTS 
/bin/cat <<EOM >>${FIND_SFTS}
#!/bin/bash

rm -f ${TARGET_DIR}/sft_database.xml.bz2 && gw_data_find --observatory L --type ${L1TYPE} --gps-start-time ${GPS0} --gps-end-time ${GPS1} --match localhost --server=${LIGO_DATAFIND_SERVER} | ${SCRIPTS}/AddSFTsToDatabase.pl && gw_data_find --observatory H --type ${H1TYPE} --gps-start-time ${GPS0} --gps-end-time ${GPS1} --match localhost --server=${LIGO_DATAFIND_SERVER} | ${SCRIPTS}/AddSFTsToDatabase.pl

EOM

#
## FIND_SFTS_SUB #################################
FIND_SFTS_SUB=${TARGET_DIR}/jobs/find_sfts/find_sfts.sub

/bin/cat <<EOM >>${FIND_SFTS_SUB}
${ACCOUNT_HEADER}
universe   = vanilla
executable = ${FIND_SFTS}
getenv = true
notification = never
log        = condor.log
output     = condor.out
error      = condor.error
queue
EOM
##################################################

#
## WAIT        #################################
/bin/cat <<EOM >>${WAIT}
${ACCOUNT_HEADER}
universe   = vanilla
executable = ${SCRIPTS}/wait.sh
arguments  = 65
log        = wait.log
output     = wait.out
error      = wait.error
queue
EOM
##################################################



##################################################################
#
##  Make pre/post shell scripts executable
for i in $(ls ${DAG_DIR}/*.sh); do 
   chmod +x ${i}
done

########  End of set_up_search_DAG.sh ############################################
