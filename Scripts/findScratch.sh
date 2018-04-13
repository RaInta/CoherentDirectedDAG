#!/bin/bash
#
#  TIRED of constantly setting your local scratch directory every time you 
# switch to a new LIGO data analysis machine?
#
# Have no fear! This script tries to automagically set a 
# SCRATCH_DIR directory based on finding your local host.
#
# Created: 4 June 2014, Ra Inta
# Modified: 20160325, R.I.

# scripts directory
SCRIPTS=`dirname $0`

LOCAL_HOST=`hostname -f` 
#echo "Currently running on ${LOCAL_HOST}"
#echo $SCRATCH

case "${LOCAL_HOST}" in
   atlas[0-9].atlas.aei.uni-hannover.de)
      #SCRATCH_DIR=${SCRATCH}
      SCRATCH_DIR=/atlas/data/scratchtest/${USER}
      ;;
   titan[0-9].atlas.aei.uni-hannover.de)
      #SCRATCH_DIR=${SCRATCH}
      SCRATCH_DIR=/atlas/data/scratchtest/${USER}
      ;;
   atlas[0-9].atlas.local)
      #SCRATCH_DIR=${SCRATCH}
      SCRATCH_DIR=/atlas/data/scratchtest/${USER}
      ;;
   titan[0-9].atlas.local)
      #SCRATCH_DIR=${SCRATCH}
      SCRATCH_DIR=/atlas/data/scratchtest/${USER}
      ;;
   ldas-pcdev[0-9].ligo.caltech.edu)
      SCRATCH_DIR=/usr1/${USER}
      ;;
   "ldas-grid.ligo.caltech.edu")
      SCRATCH_DIR=/usr1/${USER}
      ;;
   "ligo-wa.ligo.caltech.edu")
      SCRATCH_DIR=/usr1/${USER}
      ;;
   "ligo-la.ligo.caltech.edu")
      SCRATCH_DIR=/usr1/${USER}
      ;;
   pcdev[0-9].phys.uwm.edu)
      SCRATCH_DIR=/localscratch/${USER} #SCRATCH_DIR=/people/${USER}  # Need to check Nemo's scratch)
      ;;
   "marlin.phys.uwm.edu")
      SCRATCH_DIR=/localscratch/${USER} #SCRATCH_DIR=/people/${USER}
      ;;
   "hydra.phys.uwm.edu")
      SCRATCH_DIR=/localscratch/${USER} #SCRATCH_DIR=/people/${USER}
      ;;
   "trout.phys.uwm.edu")
      SCRATCH_DIR=/localscratch/${USER} #SCRATCH_DIR=/people/${USER}
      ;;
   "sugar.phy.syr.edu")
      SCRATCH_DIR=/usr1/${USER}
      ;;
   "sugar-dev1.phy.syr.edu")
      SCRATCH_DIR=/usr1/${USER}
      ;;
   "spice-dev1.phy.syr.edu")
      SCRATCH_DIR=/usr1/${USER}
      ;;
   "stampede.tacc.xsede.org")
      SCRATCH_DIR=${SCRATCH}
      ;;
      *)
      echo "There has been an error assigning your SCRATCH directory. Your host may not be supported."
      exit 1
      ;;
esac


#echo "Setting SCRATCH directory to ${SCRATCH}_DIR"

#echo "export SCRATCH_DIR=${SCRATCH_DIR}"
#echo "export LOCAL_HOST=${LOCAL_HOST}"

#$(echo "export SCRATCH_DIR=${SCRATCH_DIR}")
#$(echo "export LOCAL_HOST=${LOCAL_HOST}")

echo "${SCRATCH_DIR}"

exit 0
