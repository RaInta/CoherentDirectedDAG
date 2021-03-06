#!/usr/bin/perl
#$Id: Search.pl,v 1.9 2013/02/06 15:46:32 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use Getopt::Long;

# parse options
my ($job, $freq, $band);
my $verbose = 1;
GetOptions 
    'job=i'  => \$job,
    'freq=f' => \$freq,
    'band=f' => \$band,
    'v:+'    => \$verbose;
assert_positive '--job',  $job;
assert_positive '--freq', $freq;
assert_positive '--band', $band;

# print out some job information
print '=' x 10, "\n";
print "Job number: $job\n";
print "Search starting frequency: $freq\n";
print "Search frequency band: $band\n";
print '=' x 10, "\n";

# read setup XMLs
my ($right_ascension, $declination, $spindown_age);
my ($min_braking, $max_braking, $max_mismatch);
my ($rng_med_window, $ephem_year, $keep_threshold);
read_setup_xmls 
    'target:right_ascension' => \$right_ascension,
    'target:declination'     => \$declination,
    'target:spindown_age'    => \$spindown_age,
    'target:min_braking'     => \$min_braking,
    'target:max_braking'     => \$max_braking,
    'search:max_mismatch'    => \$max_mismatch,
    'search:rng_med_window'  => \$rng_med_window,
    'search:ephem_year'      => \$ephem_year,
    'search:keep_threshold'  => \$keep_threshold;

# get path to SFTs
my $search_sfts = get_check_local_sfts $job; 

# run search
# This version of lalapps runs with SSE2 extensions by default:
## The first argument is a bug workaround!!! there is no option for a space in the argument
#run_exec '/home/ra/analysis/simulations/devWheezy/production/bin/lalapps_ComputeFStatistic_v2', {
run_exec '/home/ra/searches/PostCasA/Scripts/production/bin/lalapps_ComputeFStatistic_v2_SSE', {
    'v'                    => $verbose,
    'Alpha'                => $right_ascension,
    'Delta'                => $declination,
    'Freq'                 => $freq,
    'FreqBand'             => $band,
    'DataFiles'            => "$search_sfts/*.sft",
    'ephemDir'             => LAL_DATA_PATH,
    'ephemYear'            => $ephem_year,
    'RngMedWindow'         => $rng_med_window,
    'Dterms'               => FSTAT_DTERMS,
    'gridType'             => '9',
    'spindownAge'          => $spindown_age,
    'minBraking'           => $min_braking,
    'maxBraking'           => $max_braking,
    'metricMismatch'       => $max_mismatch,
    'TwoFthreshold'        => $keep_threshold,
    'outputLogPrintf'      => "search.log.$job",
    'outputFstat'          => "search_results.txt.$job",
    'outputFstatHist'      => "search_histogram.txt.$job",
    'timerCount'           => "10000000",
    'outputSingleFstats'   => "TRUE",
};

# delete condor submit file for this job
#system "rm -f search.sub.$job";

exit 0;
