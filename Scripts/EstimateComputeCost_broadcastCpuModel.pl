#!/usr/bin/perl
#$Id: EstimateComputeCost.pl,v 1.5 2012/05/31 08:41:50 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use File::Spec;

use constant NUM_OF_SFTS  => 480;
use constant NUM_OF_TEMPL => 10000000;
#use constant NUM_OF_SFTS  => 480;   # These two values are closer to an actual small search...just testing for resampling
#use constant NUM_OF_TEMPL => 351281880;

# make sure there's no SFTs in current directory
assert_no_files_matching '*.sft';

# read setup XMLs
my $sft_span_time;
read_setup_xmls 
    'sft:span_time' => \$sft_span_time;

system("cat /proc/cpuinfo | grep \"model name\"\n\n");

# make fake SFTs
run_exec 'lalapps_Makefakedata_v4', {
    'outSFTbname' => './',
    'IFO'         => 'L1',
    #'ephemDir'    => LAL_DATA_PATH,
    #'ephemYear'   => '09-11',
    'startTime'   => '1100000000',
    'Tsft'        => $sft_span_time,
    'duration'    => $sft_span_time * NUM_OF_SFTS,
    #'fmin'        => '99.0',
    #'Band'        => '3.0',
    'fmin'        => '1695.0',
    'Band'        => '10.0',
    'Alpha'       => '6',
    'Delta'       => '1',
    'noiseSqrtSh' => '1.0'
    };

# run a search over them
my $start = time;
run_exec 'lalapps_ComputeFstatistic_v2', {
    'Alpha'       => '6',
    'Delta'       => '1',
    #'Freq'        => '100.0',
    #'FreqBand'    => '1.0',
    'Freq'        => '1700.0',
    'FreqBand'    => '1.0',
    'dFreq'       => 1.0 / NUM_OF_TEMPL,
    'DataFiles'   => './*.sft',
    #'ephemDir'    => LAL_DATA_PATH,
    #'ephemYear'   => '09-11',
    'gridType'    => '0',
    'metricType'  => '0',
    #'computeBSGL' => 'True', 
    'FstatMethod' => 'ResampBest'
    #'FstatMethod' => 'ResampBest'
    };
my $diff = time - $start;
print "Time taken was $diff seconds\n";

# calculate an estimate of the compute cost per template/SFT
my $cost = $diff / NUM_OF_SFTS / NUM_OF_TEMPL;

# write setup XML file
write_comp_cost_xml
    'compute:cost' => $cost;

# delete SFTs
system 'rm -rf *.sft';

exit 0;
