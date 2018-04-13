#!/bin/bash

# Should be scripts directory
LALSUITE_SRCDIR=${PWD}
LALSUITE_PREFIX=${PWD}/production
MYFLAGS="--prefix=${LALSUITE_PREFIX} --disable-debug CFLAGS=-O3"

if ! [ -e 'lalsuite' ]; then
  git clone git://ligo-vcs.phys.uwm.edu/lalsuite.git
  cd lalsuite
  # The following git-hash 
  # Supports lalapps_LatticeTilingCount and deprecated options
  # Date:   Thu May 26 13:51:32 2016 -0700 
  git checkout 770d04f756714eead8aa0d97c305253c799dd4e8 
  ./00boot
  ./configure ${MYFLAGS}
  make -j
  make install
fi

# Source lalsuiterc and add this to .bash_profile as a default
echo ". ${LALSUITE_PREFIX}/etc/lalsuiterc" >> ${HOME}/.bash_profile

. ${LALSUITE_PREFIX}/etc/lalsuiterc
