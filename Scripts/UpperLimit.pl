#!/usr/bin/perl
#$Id: UpperLimit.pl,v 1.7 2014/06/06 17:02:00 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use Getopt::Long;
use File::Spec;
use POSIX ();

use constant INJ_PER_SUBJOB => 250;

# parse options
my ($job);
my $injections = 0;
my $verbose = 1;
GetOptions 
    'job=i'        => \$job,
    'injections=i' => \$injections,
    'v:+'          => \$verbose;
assert_positive '--job',  $job;

# read setup XMLs
my ($right_ascension, $declination);
my ($rng_med_window, $ephem_year);
my ($max_mismatch, $FDR);
read_setup_xmls 
    'target:right_ascension'      => \$right_ascension,
    'target:declination'          => \$declination,
    'search:rng_med_window'       => \$rng_med_window,
    'search:ephem_year'           => \$ephem_year,
    'search:max_mismatch'         => \$max_mismatch,
    'upper_limit:false_dismissal' => \$FDR;

# read upper limit bands
my %ul_bands;
read_ul_bands_db \%ul_bands;
die "Couldn't find upper limit band for job $job" if !defined($ul_bands{$job});
my $ul_freq = $ul_bands{$job}->{freq};
my $ul_band = $ul_bands{$job}->{band};
my $loudest_2F = $ul_bands{$job}->{loudest_nonvetoed_template}->{twoF};

# get path to SFTs
my $ul_sfts = get_check_local_sfts $job;

# compute upper limit for this band
run_exec 'lalapps_ComputeFStatAnalyticMonteCarloUpperLimit', {
    'v'                => $verbose,
    'alpha'            => $right_ascension,
    'delta'            => $declination,
    'freq'             => $ul_freq,
    'freq-band'        => $ul_band,
    'loudest-2F'       => $loudest_2F,
    'mism-hist-file'   => UL_MISM_HISTOGRAM,
    'max-mismatch'     => $max_mismatch,
    'sft-patt'         => "$ul_sfts/*.sft",
    'ephem-dir'        => LAL_DATA_PATH,
    'ephem-year'       => $ephem_year,
    'rng-med-win'      => $rng_med_window,
    'false-dism'       => $FDR,
    'output-file'      => "upper_limit.txt.$job",
    '2F-pdf-hist-file' => "upper_limit_histogram.txt.$job",
    '2F-pdf-hist-binw' => UL_HIST_BINWIDTH,
};

# if no injections, we're done
exit 0 if ($injections == 0);

# get the upper limit
my $h0;
open FILE, "upper_limit.txt.$job" or die "Couldn't open 'upper_limit.txt.$job'";
while (my $line = <FILE>) {
    chomp $line;
    next if $line =~ /^%/;
    foreach my $var (split /\s+/, $line) {
	if ($var =~ /^h0=(.+)$/) {
	    $h0 = $1;
	    last;
	}
    }
}
close FILE;
die "Couldn't get the upper limit from 'upper_limit.txt.$job'" if !defined($h0);

# create subdirectory for injections
assert_directory $job;
chdir $job;

# create condor submission files for injections
my @subjob_injections;
while ($injections >= INJ_PER_SUBJOB) {
    push @subjob_injections, INJ_PER_SUBJOB;
    $injections -= INJ_PER_SUBJOB;
}
if ($injections > 0) {
    push @subjob_injections, $injections;
}
for (my $subjob = 0; $subjob < @subjob_injections; ++$subjob) {
    condor_sub_file "upper_limit_injections.sub.$job.$subjob",
        'executable' => 'UpperLimitInjections_new.pl',
        'output'     => "condor.out.$job.$subjob",
        'error'      => "condor.err.$job.$subjob",
        'arguments'  => "--job $job --subjob $subjob --h0 $h0 --injections $subjob_injections[$subjob]",
        'queue'      => 1;
}

exit 0;
