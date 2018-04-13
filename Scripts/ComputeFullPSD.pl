#!/usr/bin/perl
#$Id: ComputeFullPSD.pl,v 1.1 2013/01/06 17:05:05 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use File::Spec;

# read setup XMLs
my ( $rng_med_win, $ul_band );
read_setup_xmls
    'search:rng_med_window' => \$rng_med_win,
    'upper_limit:band'      => \$ul_band;

# get location of global SFTs
my $global_sfts = GLOBAL_DIR('sfts');
assert_directory $global_sfts;

# remove output file if it exists; then open for appending
if (-e "full_psd.dat") {
    system "rm full_psd.dat";
}
open OUT, ">>full_psd.dat" or die "Couldn't open 'full_psd.dat': $!";

# break into 5 Hz bands to cut down on memory usage
my $f_start = 10;
while ($f_start < 2000) {

    my @psd = run_exec_output 'lalapps_ComputePSD', {
       'outputPSD'     => "/dev/stdout",
       'PSDmthopSFTs'  => 4,  # harmonic mean
       'PSDmthopIFOs'  => 4,  # harmonic mean
       'PSDmthopBins'  => 4,  # harmonic mean
       'binSizeHz'     => $ul_band,
       'fStart'        => $f_start,
       'fBand'         => 5,
       'blocksRngMed'  => $rng_med_win,
       'inputData'     => File::Spec->catfile($global_sfts, '*.sft'),
        };

    # output the SFT path together with the info
    print OUT map { "$_\n" } @psd;

    # advance
    $f_start += 5;
}

# close output file
close OUT;

exit 0;
