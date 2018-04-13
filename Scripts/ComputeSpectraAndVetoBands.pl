#!/usr/bin/perl
#$Id: ComputeSpectraAndVetoBands.pl,v 1.10 2013/08/30 15:13:22 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use File::Spec;
use List::Util;

# read setup XMLs
my ($start_freq, $search_band, $rng_med_win);
my ($veto_thresh, $ul_band, $ifos, $start_time, $end_time);
read_setup_xmls 
    'search:freq'             => \$start_freq, 
    'search:band'             => \$search_band,
    'search:rng_med_window'   => \$rng_med_win,
    'sft:ifos'                => \$ifos,
    'stretch:start_time'      => \$start_time,
    'stretch:end_time'        => \$end_time,
    'upper_limit:veto_thresh' => \$veto_thresh;
my $end_freq = $start_freq + $search_band;
my @ifos = split /\s+/, $ifos;

# veto window is number of Dterms summed by CFS_v2
my $veto_win = 2 * FSTAT_DTERMS;

# get location of global SFTs
my $global_sfts = GLOBAL_DIR('sfts');
assert_directory $global_sfts;

foreach my $ifo (@ifos) {

    # generate the fscan spectra and spectrogram
    run_exec 'lalapps_spec_avg', {
	'outputBname'  => "fscan_sfts_${ifo}",
	'SFTs'         => File::Spec->catfile($global_sfts, '*.sft'),
	'blocksRngMed' => $rng_med_win,
	'startGPS'     => $start_time,
	'endGPS'       => $end_time,
	'IFO'          => $ifo,
	'fMin'         => $start_freq,
	'fMax'         => $end_freq,
	'timeBaseline' => 1800,
	'freqRes'      => 0.1,
    };

    # generate power spectra
    run_exec 'lalapps_ComputePSD', {
	'outputPSD'     => "psd_sfts_${ifo}",
	'inputData'     => File::Spec->catfile($global_sfts, '*.sft'),
	'blocksRngMed'  => $rng_med_win,
	'startTime'     => $start_time,
	'endTime'       => $end_time - 1800,
	'IFO'           => $ifo,
	'fStart'        => $start_freq,
	'fBand'         => $search_band,
	'PSDmthopSFTs'  => 4,  # harmonic mean
    };

}

my (%fh, @win_freq, %win_power, $eof);

# open fscan time-averaged spectra
%fh = ();
foreach my $ifo (@ifos) {
    my $file = "fscan_sfts_${ifo}.txt";
    open $fh{$ifo}, $file or die "Couldn't open '$file': $!"
}

my @veto_bands;

# read in spectra and veto bands with power above threshold
@win_freq = ();
%win_power = ();
$eof = 0;
while (!$eof) {

    # read in next frequency and power
    my $freq;
    my %power;
    $eof = 1;
    foreach my $ifo (@ifos) {
	
	# read in line from file
	my $line = readline $fh{$ifo};
	die "Read past end of file" if !defined($line);
	$eof = 0 if !eof($fh{$ifo});
	chomp $line;
	$line =~ s/^\s+//;
	$line =~ s/\s+$//;

	# split line
	my ($f, $p, $s) = split /\s+/, $line;

	# check that frequencies match
	die "Frequencies do not match" if (defined($freq) && $f != $freq);

	# set frequency and power (this is now in standard deviations)
	$freq = $f;
	$power{$ifo} = abs($s);

    }

    # add frequency and power to windows
    push @win_freq, $freq;
    foreach my $ifo (@ifos) {
	push @{$win_power{$ifo}}, $power{$ifo};
    }
    while (@win_freq > $veto_win) {
	shift @win_freq;
	foreach my $ifo (@ifos) {
	    shift @{$win_power{$ifo}};
	}
    }
    
    # if window is full
    if (@win_freq == $veto_win) {

	# get the maximum power (std. deviations) in the window over all IFOs
	my $max_power = undef;
	foreach my $ifo (@ifos) {
	    die "Unequal windows" if (@{$win_power{$ifo}} != $veto_win);
	    $max_power = List::Util::max($max_power, @{$win_power{$ifo}});
	}

	# if power is greater than veto threshold, veto window
	if ($max_power > $veto_thresh) {

	    # calculate frequency and band to veto
	    my $freq = $win_freq[0];
	    my $band = ($win_freq[-1] - $freq) + ($win_freq[-1] - $win_freq[-2]);

	    # if window overlaps with previously vetoed band, expand that band
	    if (@veto_bands > 0 && do_bands_intersect($freq, $band, $veto_bands[-1]->{freq}, $veto_bands[-1]->{band})) {
		my $fmin = List::Util::min($veto_bands[-1]->{freq}, $freq);
		my $fmax = List::Util::max($veto_bands[-1]->{freq} + $veto_bands[-1]->{band}, $freq + $band);
		$veto_bands[-1]->{freq} = $fmin;
		$veto_bands[-1]->{band} = $fmax - $fmin;
		$veto_bands[-1]->{power} = List::Util::max($veto_bands[-1]->{power}, $max_power);
	    }
	    
	    # otherwise add new band to veto list
	    else {
		my %veto;
		$veto{freq} = $freq;
		$veto{band} = $band;
		$veto{power} = $max_power;
		push @veto_bands, {%veto};
	    }

	}

    }

}

# close files
foreach my $ifo (@ifos) {
    close $fh{$ifo};
}

# add extra veto bands from file, if it exists
if ( -f "extra_veto_bands.txt") {
    print "Adding extra veto bands from 'extra_veto_bands.txt'\n";
    open FILE, "extra_veto_bands.txt" or die "Couldn't open 'extra_veto_bands.txt': $!";
    while (<FILE>) {
        chomp;
        my %veto;
        my $remainder;
        ($veto{freq}, $veto{band}, $remainder) = split /\s+/;
        push @veto_bands, {%veto};
    }
}
else {
    print "Skipping extra veto bands: 'extra_veto_bands.txt' not found\n";
}

# write veto bands
my %veto_bands;
foreach my $veto_band (@veto_bands) {
    foreach my $key (keys %{$veto_band}) {
	$veto_bands{$veto_band->{freq}}->{$key} = $veto_band->{$key};
    }
}
write_veto_bands_db \%veto_bands;

# compress fscan and power spectra
!system "rm -f fscan_sfts_*.bz2 psd_sfts_*.bz2" or die "rm failed: $!";
!system "bzip2 -v fscan_sfts_* psd_sfts_*" or die "bzip2 failed: $!";

exit 0;
