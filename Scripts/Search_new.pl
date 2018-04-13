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
    #'search:ephem_year'      => \$ephem_year,
    'search:keep_threshold'  => \$keep_threshold;

# get path to SFTs
my $search_sfts = get_check_local_sfts $job; 



# This kludge is needed merely because of a bug in this version of CFS_v2 regarding --outputSingleFstats requires an '=':
#system ("/home/ra/analysis/simulations/devWheezy/production/bin/lalapps_ComputeFStatistic_v2", "--Alpha=$right_ascension", "--Delta=$declination", "--Freq=$freq", "--FreqBand=$band", "--DataFiles=$search_sfts/*.sft", "--RngMedWindow=$rng_med_window", "--Dterms=8", "--gridType=9", "--spindownAge=$spindown_age", "--minBraking=$min_braking", "--maxBraking=$max_braking", "--metricMismatch=$max_mismatch", "--TwoFthreshold=$keep_threshold", "--outputLogPrintf=search.log.$job", "--outputFstat=search_results.txt.$job", "--outputFstatHist=search_histogram.txt.$job", "--timerCount=10000000", "--outputSingleFstats=TRUE", "--FstatMethod=ResampBest",  "--ephemSun=/home/ra/analysis/simulations/devWheezy/production/share/lalpulsar/sun00-19-DE405.dat.gz","--ephemEarth=/home/ra/analysis/simulations/devWheezy/production/share/lalpulsar/earth00-19-DE405.dat.gz" );
#system ("/home/ra/analysis/simulations/devWheezy/production/bin/lalapps_ComputeFStatistic_v2", "--Alpha=$right_ascension", "--Delta=$declination", "--Freq=$freq", "--FreqBand=$band", "--DataFiles=$search_sfts/*.sft", "--ephemSun=/home/ashikuzzaman.idrisy/TestResamp/sun00-19-DE405.dat.gz","--ephemEarth=/home/ashikuzzaman.idrisy/TestResamp/earth00-19-DE405.dat.gz","--RngMedWindow=$rng_med_window", "--Dterms=8", "--gridType=9", "--spindownAge=$spindown_age", "--minBraking=$min_braking", "--maxBraking=$max_braking","--metricMismatch=$max_mismatch", "--TwoFthreshold=$keep_threshold", "--outputLogPrintf=search.log.$job", "--outputFstat=search_results.txt.$job", "--outputFstatHist=search_histogram.txt.$job", "--timerCount=10000000", "--outputSingleFstats=TRUE", "--FstatMethod=ResampBest");

#my $start = time;
#system ("/home/ra/searches/O1/Scripts/production/bin/lalapps_ComputeFstatistic_v2", "--Alpha=$right_ascension", "--Delta=$declination", "--Freq=$freq", "--FreqBand=$band", "--DataFiles=$search_sfts/*.sft", "--RngMedWindow=$rng_med_window", "--Dterms=8", "--gridType=9", "--spindownAge=$spindown_age", "--minBraking=$min_braking", "--maxBraking=$max_braking","--metricMismatch=$max_mismatch", "--TwoFthreshold=$keep_threshold", "--outputLogPrintf=search.log.$job", "--outputFstat=search_results.txt.$job", "--outputFstatHist=search_histogram.txt.$job", "--timerCount=10000000", "--outputSingleFstats=TRUE", "--FstatMethod=ResampBest", "--computeBSGL=True");
#my $diff = time - $start;
#print "Time taken for SSE2 was $diff seconds\n";

#my $start = time;
#system ("/home/ra/searches/O1/Scripts/production/bin/lalapps_ComputeFstatistic_v2", "--Alpha=$right_ascension", "--Delta=$declination", "--Freq=$freq", "--FreqBand=$band", "--DataFiles=$search_sfts/*.sft", "--RngMedWindow=$rng_med_window", "--Dterms=8", "--gridType=9", "--spindownAge=$spindown_age", "--minBraking=$min_braking", "--maxBraking=$max_braking","--metricMismatch=$max_mismatch", "--TwoFthreshold=$keep_threshold", "--outputLogPrintf=search.log.$job", "--outputFstat=search_results.txt.$job", "--outputFstatHist=search_histogram.txt.$job", "--timerCount=10000000", "--outputSingleFstats=TRUE", "--FstatMethod=ResampBest", "--computeBSGL=True");
#my $diff = time - $start;
#print "Time taken for Resamp was $diff seconds\n";

## calculate f3dot bounds
## this is correct for negative fdot and negative f3dot (f3dot goes like fdot^3)
## searching over spinup would require a correction
#my ($f_min, $f_max, $fdot_min, $fdot_max,$f3dot_min,$f3dot_max,$f3dot_Band);
#my $f_min = $freq;
#my $f_max = $freq + $band;
## fdot = - (freq/((n-1)*tau))
#my $fdot_min = - ($f_max/(($min_braking - 1)*$spindown_age));
#my $fdot_max = - ($f_min/(($max_braking - 1)*$spindown_age));
## f3dot = (2n-1)n(fdot^3/freq^2)
#my $f3dot_min = (2*$max_braking-1)*$max_braking*(($fdot_min*$fdot_min*$fdot_min)/($f_min*$f_min));
#my $f3dot_max = (2*$min_braking-1)*$min_braking*(($fdot_max*$fdot_max*$fdot_max)/($f_max*$f_max));
#my $f3dot_Band = $f3dot_max - $f3dot_min;
## run search
my $start = time;
run_exec 'lalapps_ComputeFstatistic_v2', {
    #'v'                    => $verbose,
    'Alpha'                => $right_ascension,
    'Delta'                => $declination,
    'Freq'                 => $freq,
    'FreqBand'             => $band,
    'DataFiles'            => "$search_sfts/*.sft",
    #'ephemDir'             => LAL_DATA_PATH,
    #'ephemYear'            => $ephem_year,
    'RngMedWindow'         => $rng_med_window,
    'Dterms'               => FSTAT_DTERMS,
    'gridType'             => '9',
    'spindownAge'          => $spindown_age,
    'minBraking'           => $min_braking,
    'maxBraking'           => $max_braking,
    #'f3dot'                => $f3dot_min,
    #'f3dotBand'            => $f3dot_Band,
    'metricMismatch'       => $max_mismatch,
    'TwoFthreshold'        => $keep_threshold,
    #'outputLogPrintf'      => "search.log.$job",
    'outputFstat'          => "search_results.txt.$job",
    'outputFstatHist'      => "search_histogram.txt.$job",
    'timerCount'           => "10000000",
    'FstatMethod'          => "ResampBest",
    'outputSingleFstats'   => "TRUE",
    'computeBSGL'          => "TRUE"
};
my $diff = time - $start;
print "Time taken for resampling was $diff seconds\n";

# delete condor submit file for this job
system "rm -f search.sub.$job";

exit 0;
