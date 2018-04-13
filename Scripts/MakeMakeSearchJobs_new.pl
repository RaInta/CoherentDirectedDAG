#!/usr/bin/perl

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon_new;
use Getopt::Long;

# parse command line
my $account_group;
my $account_user;
my $job_hours;

GetOptions (
    'account-group=s'  => \$account_group,
    'account-user=s'   => \$account_user,
    'job-hours=s'   => \$job_hours,
    );

# create condor submission file
condor_sub_file 'create_search_jobs.sub',
    'accounting_group'  => "$account_group",
    'accounting_group_user'   => "$account_user",
    'executable'     => "MakeSearchJobs_new.pl",
    'output'         => "condor.out",
    'error'          => "condor.err",
    'queue'          => 1;

exit 0;
