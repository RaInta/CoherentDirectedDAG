#!/usr/bin/perl
#$Id: UpperLimitInjections.pl,v 1.9 2012/12/22 02:33:18 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use Getopt::Long;
use POSIX ();
use File::Spec;

use constant PI => 3.141592653589793;

# parse options
my ($job, $subjob, $h0, $injections);
GetOptions 
    'job=i'        => \$job,
    'subjob=i'     => \$subjob,
    'h0=f'         => \$h0,
    'injections=i' => \$injections;
assert_positive '--job',        $job;
assert_positive '--subjob',     $subjob;
assert_positive '--h0',         $h0;
assert_positive '--injections', $injections;

# form job ID
my $id = "$job.$subjob";

# read setup XMLs
my ($right_ascension, $declination);
my ($spindown_age, $min_braking, $max_braking);
my ($span_time, $max_mismatch);
my ($ifos, $start_time);
my ($rng_med_window, $ephem_year, $FDR);
read_setup_xmls 
    'target:right_ascension'      => \$right_ascension,
    'target:declination'          => \$declination,
    'target:spindown_age'         => \$spindown_age,
    'target:min_braking'          => \$min_braking,
    'target:max_braking'          => \$max_braking,
    'search:span_time'            => \$span_time,
    'search:max_mismatch'         => \$max_mismatch,
    'search:rng_med_window'       => \$rng_med_window,
    'search:ephem_year'           => \$ephem_year,
    'sft:ifos'                    => \$ifos,
    'stretch:start_time'          => \$start_time,
    'upper_limit:false_dismissal' => \$FDR;
my @ifos = split /\s+/, $ifos;

# read upper limit bands
my %ul_bands;
read_ul_bands_db \%ul_bands;
die "Couldn't find upper limit band for job $job" if !defined($ul_bands{$job});
my $ul_freq = $ul_bands{$job}->{freq};
my $ul_band = $ul_bands{$job}->{band};
my $search_2F = $ul_bands{$job}->{loudest_nonvetoed_template}->{twoF};

# get path to SFTs
my $ul_sfts = get_check_local_sfts $id;

# create local injection base directory
my $inj_base_dir = LOCAL_DIR('upper_limit_injections');
assert_directory $inj_base_dir;
my $inj_base_dir = File::Spec->catdir($inj_base_dir, $id);
assert_directory $inj_base_dir;
!system "rm -rf $inj_base_dir/*" or die "Couldn't remove all files in '$inj_base_dir': $!";

# create directories for banded SFTs and injection files
my $banded_sft_dir = File::Spec->catdir($inj_base_dir, "sfts");
assert_directory $banded_sft_dir;
my $injection_dir = File::Spec->catdir($inj_base_dir, "injections");
assert_directory $injection_dir;

# create narrow-band SFTs in local directory
run_exec 'lalapps_ConvertToSFTv2', {
    'inputSFTs' => "$ul_sfts/*.sft",
    'fmin'      => $ul_freq - 0.5*$ul_band,
    'fmax'      => $ul_freq + 1.5*$ul_band,
    'outputDir' => $banded_sft_dir,
};

# inverse metric diagonal elements
my @diag_inv_metric = (
		       300   / (PI**2 * $span_time**2),
		       6480  / (PI**2 * $span_time**4),
		       25200 / (PI**2 * $span_time**6),
		       );

# size of bounding box around metric ellipse
my @bounding_box = map { 2.0 * sqrt($_ * $max_mismatch) } @diag_inv_metric;

# open injections file
my $outputfile = File::Spec->catfile($inj_base_dir, "upper_limit_injections.txt.$id");
open FILE, ">$outputfile" or die "Couldn't open '$outputfile'";
print FILE '%% $Id: UpperLimitInjections.pl,v 1.9 2012/12/22 02:33:18 owen Exp $', "\n";
printf FILE "search_2F=%0.4f upper_limit_h0=%0.4e\n", $search_2F, $h0;
printf FILE "injections=%i\n", $injections;

# do injections
for (my $i = 0; $i < $injections; ++$i) {
    print '@' x 10, "\n";
    print "Starting injection @{[$i+1]} of $injections\n";

    # create random nuisance parameters
    my $cosi = -1 + rand() * 2,
    my $psi  =      rand() * 2*PI,
    my $phi0 =      rand() * 2*PI,
        
    # create random frequency and spindowns
    my @freq;
    {
	$freq[0] = $ul_freq + rand() * $ul_band;
    }
    {
	my $f1_min = -$freq[0] / (($min_braking - 1) * $spindown_age);
	my $f1_max = -$freq[0] / (($max_braking - 1) * $spindown_age);
	$freq[1] = $f1_min + rand() * ($f1_max - $f1_min);
    }
    {
	my $f2_min = $min_braking * $freq[1]**2 / $freq[0];
	my $f2_max = $max_braking * $freq[1]**2 / $freq[0];
	$freq[2] = $f2_min + rand() * ($f2_max - $f2_min);
    }

    # work out search box around signal
    my @srch_freq;
    my @srch_band;
    for (my $j = 0; $j < 3; ++$j) {
	$srch_freq[$j] = $freq[$j] - (4.0 + rand()) * $bounding_box[$j];
	$srch_band[$j] =             (4.0 * 2 + 1)  * $bounding_box[$j];
    }

    # add this extra padding to fake SFTs
    my $srch_pad  = 0.4;

    # start CPU timing of injection
    my $CPU_start = time;
    
    # make fake SFTs with fake signal and real noise
    foreach my $ifo (@ifos) {
	run_exec 'lalapps_Makefakedata_v4', {
	    'generationMode'  => 1,
	    'outSFTbname'     => "$injection_dir",
	    'IFO'             => $ifo,
	    #'ephemDir'        => LAL_DATA_PATH,
            'ephemDir'        => "/home/ra/searches/O1/Scripts/production/share/lalpulsar",
	    'ephemYear'       => $ephem_year,
	    'fmin'            => sprintf("%.2f", $srch_freq[0] -   $srch_pad),
	    'Band'            => sprintf("%.2f", $srch_band[0] + 2*$srch_pad),
	    'refTime'         => $start_time,
	    'Alpha'           => $right_ascension,
	    'Delta'           => $declination,
	    'h0'              => $h0,
	    'cosi'            => $cosi,
	    'psi'             => $psi,
	    'phi0'            => $phi0,
	    'Freq'            => $freq[0],
	    'f1dot'           => $freq[1],
	    'f2dot'           => $freq[2],
	    'noiseSFTs'       => "$banded_sft_dir/*.sft",
	    'v'               => "1",
	};
    }

    # search for fake signal in fake SFTs
    my @loudest = run_exec_output 'lalapps_ComputeFStatistic_v2_SSE', {
	'refTime'             => $start_time,
	'Alpha'               => $right_ascension,
	'Delta'               => $declination,
	'Freq'                => $srch_freq[0],
	'FreqBand'            => $srch_band[0],
	'f1dot'               => $srch_freq[1],
	'f1dotBand'           => $srch_band[1],
	'f2dot'               => $srch_freq[2],
	'f2dotBand'           => $srch_band[2],
	'DataFiles'           => "$injection_dir/*.sft",
	#'ephemDir'            => LAL_DATA_PATH,
        'ephemDir'        => "/home/ra/searches/O1/Scripts/production/share/lalpulsar",
	'ephemYear'           => $ephem_year,
	'RngMedWindow'        => $rng_med_window,
	'gridType'            => '8',
	'metricMismatch'      => $max_mismatch,
	'TwoFthreshold'       => '0.0',
	'outputFstat'         => '/dev/stdout',
        'outputLogPrintf'     => "search.log.$job.$subjob",
	'outputSingleFstats'  => "TRUE",
    };

    # get the loudest 2F from the output
    my $num_templates = 0;
    my $injection_2F = undef;
    foreach (@loudest) {
	next if /^%/;
	chomp;
	++$num_templates;

	# parse the template
	my $template = parse_CFSv2_output_line $_;

	# store loudest 2F
	if (!defined($injection_2F) || $injection_2F < $template->{twoF}) {
	    $injection_2F = $template->{twoF};
	}
	
    }

    # output injection
    printf FILE "injection_2F=%0.4f num_templates=%i\n", $injection_2F, $num_templates;

    print '@' x 10, "\n";
}

# close injections file and copy to output directory
print FILE "%DONE\n";
close FILE;
!system "cp -f $outputfile @{[INITIAL_DIR]}" or die "Couldn't copy '$outputfile' to '@{[INITIAL_DIR]}': $!";

# remove local injection base directory
system "rm -rf $inj_base_dir";

# delete condor submit file for this job
system "rm -f upper_limit_injections.sub.$id";

exit 0;
