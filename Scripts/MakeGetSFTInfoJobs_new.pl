#!/usr/bin/perl

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use Getopt::Long;
use POSIX ();
use File::Spec;

# check current directory is empty of previous job files
assert_no_files_matching 'condor.*', 'get_sft_info.*';

# parse options
my $jobs = 20;
my $account_group;
my $account_user;

GetOptions ( 
    'jobs=i'           => \$jobs,
    'account-group=s'  => \$account_group,
    'account-user=s'   => \$account_user,
    );

assert_strictly_positive '--jobs', $jobs;

# read setup XMLs
my ($freq, $band);
read_setup_xmls 
    'search:freq' => \$freq, 
    'search:band' => \$band;

# read SFT database
my %sfts;
read_sft_db \%sfts;

# number of SFTs per job
my $sftsperjob = POSIX::ceil(scalar(keys %sfts) / $jobs);

# create job inputs
my $sftindex = 0;
my $jobindex = 0;
foreach my $path (keys %sfts) {

    # open file
    if ($sftindex == 0) {
	my $file = "get_sft_info.in.$jobindex";
	open FILE, ">$file" or die "Couldn't open '$file': $!";
	++$jobindex;
    }

    # print SFT path
    print FILE "$path\n";
    ++$sftindex;
    
    # close file
    if ($sftindex == $sftsperjob) {
	close FILE;
	$sftindex = 0;
    }
}
if ($sftindex > 0) {
    close FILE;
}

# create condor submission fileS
my $job = 0;
for ($job=0; $job<20; $job++){
condor_sub_file "get_sft_info.$job.sub",
    'accounting_group'  => "$account_group",
    'accounting_group_user'   => "$account_user",
    'executable'     => 'GetSFTInfo.pl',
    'arguments'      => "--freq $freq --band $band --in get_sft_info.in.$job --out get_sft_info.out.$job",
    'output'         => "condor.out.$job",
    'error'          => "condor.err.$job",
    'queue'          => 1;
}

condor_sub_file "Add_SFT_Info_Database.sub",
    'accounting_group'  => "$account_group",
    'accounting_group_user'   => "$account_user",
    'executable'     => 'AddSFTInfoToDatabase.pl',
    'output'         => "AddSFTInfo.condor.out",
    'error'          => "AddSFTInfo.condor.err",
    'queue'          => 1;

exit 0;
