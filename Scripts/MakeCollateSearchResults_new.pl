#!/usr/bin/perl
#$Id: MakeSnglCondorSub.pl,v 1.3 2011/09/28 15:38:01 owen Exp $

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
condor_sub_file 'collate_search_results.sub',
    'accounting_group'  => "$account_group",
    'accounting_group_user'   => "$account_user",
    #'executable'     => "collateSearchResults_trial.py",
    'executable'     => "CollateSearchResults_new.pl",
    'output'         => "condor.out",
    'error'          => "condor.err",
    'queue'          => 1;

exit 0;
