#!/usr/bin/perl
#$Id: AshMakeSnglCondorSubSTEP10.pl,v 1.1 2014/06/13 12:14:29 ashikuzzaman.idrisy Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;

# parse command line
#my ($executable, @arguments) = @ARGV;

# create condor submission file
condor_sub_file 'sngl_condor.sub',
    'executable' => "EstimateComputeCost.pl",
    'output'     => "condor.out",
    'error'      => "condor.err",
    'queue'      => 1;

exit 0;
