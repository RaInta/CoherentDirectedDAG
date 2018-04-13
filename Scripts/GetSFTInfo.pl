#!/usr/bin/perl
#$Id: GetSFTInfo.pl,v 1.4 2012/03/04 01:34:00 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use Getopt::Long;

# parse options
my ($freq, $band, $infile, $outfile);
GetOptions 
    'freq=f' => \$freq, 
    'band=f' => \$band, 
    'in=s'   => \$infile, 
    'out=s'  => \$outfile;
assert_strictly_positive '--freq', $freq, '--band', $band;
assert_file_exists    '--in',  $infile;
#assert_no_file_exists '--out', $outfile;

# read setup XMLs
my ($rng_med_win);
read_setup_xmls 
    'search:rng_med_window' => \$rng_med_win;

# open files
open IN, "$infile" or die "Couldn't open '$infile': $!";
open OUT, ">$outfile" or die "Couldn't open '$outfile': $!";

# iterate over SFT paths
while (my $path = <IN>) {
    chomp $path;

    # calculate harmonic mean of PSD over band
    my @psd = run_exec_output 'lalapps_ComputePSD', {
	'inputData'        => $path,
	'blocksRngMed'     => $rng_med_win,
	'fStart'           => $freq,
	'fBand'            => $band,
	'PSDmthopSFTs'     => 4,     # harmonic mean
	'PSDmthopIFOs'     => 4,     # harmonic mean
	'binSizeHz'        => $band,
	'PSDmthopBins'     => 4,     # harmonic mean
	'outputPSD'        => '/dev/stdout'
	};

    # there should be exactly one line of output after 32 comment lines
    die "PSD was not generated" if (@psd < 1);
    #die "Wrong number of lines:\n@psd" if (@psd != 33);

    # get value of harmonic mean of PSD
    ## If you're using the debug flag, we want the 29th line...
    my $meanpsd = (split /\s+/, $psd[-1])[-1];

    # output the SFT path together with the info
    print OUT "$path mean_psd=$meanpsd\n";

}

# close files
close IN;
close OUT;

exit 0;
