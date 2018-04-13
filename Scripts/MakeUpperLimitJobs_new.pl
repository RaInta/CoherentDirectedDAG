#!/usr/bin/perl

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use Getopt::Long;
use POSIX ();
use Getopt::Long;

# read setup XMLs
my ($injections);
read_setup_xmls 
    'upper_limit:num_injections' => \$injections;


my $account_group;
my $account_user;

GetOptions (
    'account-group=s'  => \$account_group,
    'account-user=s'   => \$account_user,
    );

# check current directory is empty of previous job files
assert_no_files_matching 'condor.*', 'upper_limit.*';

# get number of upper limit bands
my $num_ul_bands;
{
    my %ul_bands;
    read_ul_bands_db \%ul_bands;
    $num_ul_bands = scalar keys %ul_bands;
}

my $job=0;
# create condor submission file
for ($job=0; $job<=$num_ul_bands; $job++) {
condor_sub_file "upper_limit.$job.sub",
    'accounting_group'   => "$account_group",
    'accounting_group_user'    => "$account_user",
    'executable'      => 'UpperLimit_new.pl',
    'arguments'       => "--job $job "."--injections $injections --account-group $account_group --account-user $account_user",
    'output'          => "condor.out.$job",
    'error'           => "condor.err.$job",
    'periodic_remove' => "CurrentTime-EnteredCurrentStatus > 3600",
    'queue'           => 1;
}
exit 0;
