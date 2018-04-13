#!/usr/bin/perl
#$Id: MakeSnglCondorSub.pl,v 1.3 2011/09/28 15:38:01 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use Getopt::Long;

# parse command line
my ($executable, @arguments) = @ARGV;

# create condor submission file
condor_sub_file 'sngl_condor.sub',
    'accounting_group'  => "$account_group",
    'accounting_group_user'   => "$account_user",
    'executable'     => "$executable",
    'arguments'      => "@arguments",
    'output'         => "condor.out",
    'error'          => "condor.err",
    'queue'          => 1;

exit 0;
