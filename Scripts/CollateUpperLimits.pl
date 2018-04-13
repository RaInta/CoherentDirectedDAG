#!/usr/bin/perl
#$Id: CollateUpperLimits.pl,v 1.6 2014/06/23 23:11:28 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use POSIX ();
use List::Util;

# read upper limit bands
my %ul_bands;
read_ul_bands_db \%ul_bands;

# read upper limit information from output files
my @failed;
STDOUT->autoflush(1);
print "Processing:";
foreach my $job (sort { $a <=> $b } keys %ul_bands) {

    my $iteration = 0;
    $ul_bands{$job}->{upper_limit} = [];

    # open output file
    my $file = "upper_limit.txt.$job";
    open FILE, $file or die "Couldn't open '$file': $!";
    my $line;
    while ($line = <FILE>) {
	chomp $line;
	last if $line eq '%DONE';
	next if $line =~ /^%/;

	# get information
	my %info;
	foreach my $pair (split /\s+/, $line) {
	    my ($name, $value) = split /=/, $pair;
	    $info{$name} = $value;
	}

	# check information
	#die "Frequency '$ul_bands{$job}->{freq}' for job $job does not match '$line'"
	#    if (defined($info{freq}) && $info{freq} != $ul_bands{$job}->{freq});
	#die "Frequency '$ul_bands{$job}->{band}' for job $job does not match '$line'"
	#    if (defined($info{band}) && $info{band} != $ul_bands{$job}->{band});
	#die "'$line' does not contain 'MC_trials' and 'h0'"
	#    if (defined($info{MC_trials}) xor defined($info{h0}));

	# add information to hash
	if (defined($info{MC_trials}) && defined($info{h0})) {
	    push @{$ul_bands{$job}->{upper_limit}}, {
		iteration => ++$iteration,
		MC_trials => $info{MC_trials},
		h0        => $info{h0},
	    };
	    $ul_bands{$job}->{upper_limit_h0} = $info{h0};
	}
	
    }
    close FILE;
    push @failed, $file if ($line ne '%DONE');

    my $search_2F = $ul_bands{$job}->{loudest_nonvetoed_template}->{twoF};
    my $injections = 0;
    my $injections_below_search_2F = 0;
    my %injections_histogram;

    # collate upper limit injections
    foreach my $file (glob "$job/upper_limit_injections.txt.$job.*") {
	open FILE, $file or die "Couldn't open '$file': $!";
	my $line;
	while ($line = <FILE>) {
	    chomp $line;
	    last if $line eq '%DONE';
	    next if $line =~ /^%/;
	    
	    # get information
	    my %info;
	    foreach my $pair (split /\s+/, $line) {
		my ($name, $value) = split /=/, $pair;
		$info{$name} = $value;
	    }
	    if (defined(my $twoF = $info{injection_2F})) {
		
		# count
		++$injections;
		
		# count if below loudest 2F
		++$injections_below_search_2F if ($twoF < $search_2F);
		
		# add to histogram
		++$injections_histogram{POSIX::floor($twoF / UL_HIST_BINWIDTH)};
		
	    }
		
	}
	close FILE;
	push @failed, $file if ($line ne '%DONE');
    }

    # add information to hash and output injections histogram
    if ($injections > 0) {

	$ul_bands{$job}->{injections} = $injections;
	$ul_bands{$job}->{injections_FDR} = (1.0 * $injections_below_search_2F) / (1.0 * $injections);

	my $file = "$job/upper_limit_injections_histogram.txt.$job";
	open FILE, ">$file" or die "Couldn't open '$file': $!";
	print FILE '%% $Id: CollateUpperLimits.pl,v 1.6 2014/06/23 23:11:28 owen Exp $', "\n";
	foreach my $bin (sort { $a <=> $b } keys %injections_histogram) {
	    printf FILE "%i %i %i\n", $bin * UL_HIST_BINWIDTH, ($bin + 1) * UL_HIST_BINWIDTH, $injections_histogram{$bin};
	}
	print FILE "%DONE\n";
	close FILE;

    }

    # print progress
    print "\n  " if ($job % 10 == 0);
    printf " %4i", $job;
    
}
print "\n";
STDOUT->autoflush(0);
if (@failed > 0) {
    print "The following upper limits results files are incomplete:\n";
    print "   $_\n" foreach (@failed);
}

# For each UL band, figure out how much frequency was vetoed
my %veto_bands;
read_veto_bands_db \%veto_bands;
foreach my $ul (keys %ul_bands) {
    $ul_bands{$ul}->{band_vetoed} = 0;
    foreach my $veto (keys %veto_bands) {
	next if (!do_bands_intersect($veto_bands{$veto}->{freq}, $veto_bands{$veto}->{band}, $ul_bands{$ul}->{freq}, $ul_bands{$ul}->{band}));
	my $top = List::Util::min($veto_bands{$veto}->{freq} + $veto_bands{$veto}->{band}, $ul_bands{$ul}->{freq} + $ul_bands{$ul}->{band});
	my $bottom = List::Util::max($veto_bands{$veto}->{freq}, $ul_bands{$ul}->{freq});
	$ul_bands{$ul}->{band_vetoed} += $top - $bottom;
    }
}

# write upper limit bands
write_ul_bands_db \%ul_bands;

exit 0;
