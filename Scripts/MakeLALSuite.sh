#!/bin/bash
# Assumes we have cloned lalsuite and are in the directory above it

CVSROOT=:pserver:anonymous@gravity.phys.uwm.edu:2402/usr/local/cvs/lscsoft
MAIN=$PWD
MYFLAGS="--prefix=$MAIN/production --disable-debug CFLAGS=-O2 --disable-lalframe --disable-lalmetaio --disable-lalsimulation --disable-lalburst --disable-lalinspiral --disable-lalinference --disable-lalstochastic"

cd lalsuite
# this was the one i did all those test runs with (and was -b)
git checkout c528e710e347739bfc85cfd84ccc342159be99a1
# try a release instead
#git checkout tags/lalsuite-v6.11
# or just before karl killed the crucial test program
#git checkout 02c4127b6440f2ba513a43f0f5f42fb26ed3cfba

# should add development version too!

cd lalsuite/lal
./00boot
mkdir -p production
cd production
../configure $MYFLAGS
make
make install
source ${MAIN}/production/etc/lal-user-env.sh

cd ../../lalpulsar
./00boot
mkdir -p production
cd production
../configure $MYFLAGS
make
make install
source ${MAIN}/production/etc/lalpulsar-user-env.sh

cd ../../lalapps
./00boot
mkdir -p production
cd production
../configure $MYFLAGS
make
cd src/pulsar/FDS_isolated
make lalapps_ComputeFStatistic_v2_SSE
rm ${MAIN}/production/bin/lalapps_ComputeFStatistic_v2_SSE
ln -s ${PWD}/lalapps_ComputeFStatistic_v2_SSE ${MAIN}/production/bin/
cd ../../..
make install

# Now get the S5 code
#cd ..
#mkdir lscsoft
#cd lscsoft
#echo "" | cvs -d $CVSROOT login
#cvs -d $CVSROOT checkout -r S5CasASearch lal
#cvs -d $CVSROOT checkout -r S5CasASearch lalapps
#cvs -d $CVSROOT checkout -r S5CasASearch sftlib
#
#cd sftlib
#./00boot
#./configure --prefix=$MAIN/ancient
# BEN hacked the doc out of Makefile by hand, linked (lalapps_)SFTvalidate
#make
#make install
#
#cd ../lal
#./00boot
#./configure --prefix=$MAIN/ancient --enable-debug --enable-xml
#make
#make install
#source $MAIN/ancient/etc/lal-user-env.sh
#
#cd ../lalapps
#./00boot
#./configure --prefix=$MAIN/ancient --enable-xml
#make
#make install
# BEN manually linked new ephemerides

