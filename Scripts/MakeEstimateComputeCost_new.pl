#!/usr/bin/perl

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use Getopt::Long;

# parse command line
my $account_group;
my $account_user;

GetOptions (
    'account-group=s'  => \$account_group,
    'account-user=s'   => \$account_user,
    );

# create condor submission file
condor_sub_file 'calc_compute_cost.sub',
    'accounting_group'  => "$account_group",
    'accounting_group_user'   => "$account_user",
    'executable'     => "EstimateComputeCost_new.pl",
    'output'         => "condor.out",
    'error'          => "condor.err",
    'queue'          => 1;

exit 0;
