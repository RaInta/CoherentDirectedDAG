#!/usr/bin/perl

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use Getopt::Long;
use File::Spec;
use POSIX ();
use List::Util;

# check current directory is empty of previous job files
assert_no_files_matching 'condor.*', 'calc_template_density.*';

my $account_group;
my $account_user;

GetOptions (
    'account-group=s'  => \$account_group,
    'account-user=s'   => \$account_user,
   );

# read setup XMLs
my ($freq, $band);
read_setup_xmls 
    'search:freq' => \$freq, 
    'search:band' => \$band;

# determine the job band and step
my $jobband = List::Util::min(0.01, $band);
my $jobstep = List::Util::min(10.0, $band);

# count number of jobs
my $jobs = POSIX::ceil($band / $jobstep) + 1;

# create condor submission file
my $job = 0;
for ($job=0; $job<$jobs; $job++){
condor_sub_file "calc_template_density.$job.sub",
    'accounting_group'  => "$account_group",
    'accounting_group_user'   => "$account_user",
    'executable'     => 'CalcTemplateDensity.pl',
    'arguments'      => "--freq $freq --band $jobband --step $jobstep --job $job --jobs $jobs --out calc_template_density.out.$job",
    'output'         => "condor.out.$job",
    'error'          => "condor.err.$job",
    'queue'          => 1;
}
exit 0;
