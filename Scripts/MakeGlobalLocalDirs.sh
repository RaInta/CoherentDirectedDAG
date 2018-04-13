#!/bin/bash
#
#  MakeGlobalLocalDirs.sh
# This creates local and global directories for search targets
# It relies on the BASH script findScratch.sh
# Which looks for the SCRATCH directory on the particular
# LIGO cluster you're working on.
# 
#  IMPORTANT FEATURES:
#
# 1) You can set the global and local scratch directories to 
# be manual and distinct. You want high read capability on local,
# so might want to set this as, e.g. /atlas/user/scr01/${USER}
# on Atlas.
#
# 2) A distinct directory is created for each target (based on
# the uppermost directory name) on your local directory. This 
# prevents collisions when searching multiple targets.
#
# Created: 10 Jul 2014, Ra Inta
# Last modified: 20160404, R.I.

SCRIPTS=`dirname $0`

BASE_DIR=$(pwd)

TARG_NAME=`basename ${BASE_DIR}`

HOST_NAME=$(echo "LOCALHOST_IS_$(hostname -f)")

SCRATCH_DIR=$(${SCRIPTS}/findScratch.sh)


############################################################
# The following allows for the possibility of there being different
# local scratches for global and local directories;
# the latter especially needs to be robust to high read operations
# EDIT THIS MANUALLY IF REQUIRED:
############################################################


GLOBAL_SCRATCH=${SCRATCH_DIR}
LOCAL_SCRATCH=${SCRATCH_DIR} # Might want to change this to fast read scratch

############################################################

#for i in global local; do
#   mkdir -p ${BASE_DIR}/${i}
#   HOST_NAME=$(echo "LOCALHOST_IS_$(hostname -f)")
#   touch ${BASE_DIR}/${i}/${HOST_NAME}
#   for j in sfts upper_limit_injections; do 
#      LOCAL_DIR=${SCRATCH_DIR}/${TARG_NAME}/${i}/${j}
#      mkdir -p ${LOCAL_DIR}
#      echo ${LOCAL_DIR}
#      ln -s ${LOCAL_DIR} ${BASE_DIR}/${i}/${j}
#   done 
#done


# Make a handy empty file to remind you what head node you created 
# the local scratch on:

for i in global local; do
      mkdir -p ${BASE_DIR}/${i}
      HOST_NAME_FILE=$(echo "LOCALHOST_IS_$(hostname -f)")
      touch ${BASE_DIR}/${i}/${HOST_NAME_FILE}
done


if [[ -e ${BASE_DIR}/global/sfts ]]; then
  echo -e "Warning: ${BASE_DIR}/${i} already exists. New folder has not been written." 
else
   # Set global and local scratches separately:
   GLOBAL_DIR=${GLOBAL_SCRATCH}/${TARG_NAME}/global/sfts
   mkdir -p ${GLOBAL_DIR}
   echo "Setting global scratch: ${GLOBAL_DIR}"
   ln -s ${GLOBAL_DIR} ${BASE_DIR}/global/sfts
fi


for j in sfts upper_limit_injections; do 
   LOCAL_DIR=${LOCAL_SCRATCH}/${TARG_NAME}/local/${j}
   if [[ -e ${BASE_DIR}/local/${j} ]]; then
     echo -e "Warning: ${LOCAL_DIR} already exists. New folder has not been written."
   else
      mkdir -p ${LOCAL_DIR}
      echo "Setting local scratch: ${LOCAL_DIR}"
      # Note: switched order with -t flag on ln
      #ln -s ${BASE_DIR}/local ${LOCAL_DIR}
      ln -s ${LOCAL_DIR} ${BASE_DIR}/local/${j} 
   fi
done 


## This was for the MDC, with lots of individual targets 
#
#GLOBAL_SCRATCH=/atlas/user/atlas1/${USER}   # Note this is subject to change soon.
#
#for i in $(ls -d J*); do
#    echo "########### Target: $i    ###########"
#    cd $i
#    TARG_BASE_DIR=${GLOBAL_SCRATCH}/mdc3/${i}
#    for LOCTN in 'local' 'global'; do
#        for DESTN in 'sfts' 'upper_limit_injections'; do
#           mkdir -p ${TARG_BASE_DIR}/${LOCTN}/${DESTN}
#           ln -s ${TARG_BASE_DIR}/${LOCTN}/${DESTN} ${LOCTN}/${DESTN}
#        done
#   done
#   cd ../
#done
