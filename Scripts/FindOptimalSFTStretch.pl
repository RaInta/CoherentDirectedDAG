#!/usr/bin/perl
#$Id: FindOptimalSFTStretch.pl,v 1.3 2011/09/28 15:38:00 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use Getopt::Long;
use POSIX qw(floor ceil);
use XML::Twig;
use List::Util;

# read setup XMLs
my $stretch_window;
read_setup_xmls 
    'search:span_time' => \$stretch_window;

# read existing SFT database
my %sfts;
read_sft_db \%sfts;

# get SFT information from database
my $min_start;
my $max_start;
my $min_mean_psd;
my $span_time;
my $num_ifos;
{
    my %ifos;
    foreach my $path (keys %sfts) {
	
	$ifos{$sfts{$path}->{ifo}} = 1;
	
	my $start = $sfts{$path}->{start_time};
	$min_start = $start if (!defined($min_start) || $start < $min_start);
	$max_start = $start if (!defined($max_start) || $start > $max_start);
	
	my $mean_psd = $sfts{$path}->{mean_psd};
	die "'mean_psd' not defined in SFT database" if !defined($mean_psd);
	$min_mean_psd = $mean_psd if (!defined($min_mean_psd) || $mean_psd < $min_mean_psd);
	
	die "'span_time' is inconsistent" if (defined($span_time) && $span_time != $sfts{$path}->{span_time});
	$span_time = $sfts{$path}->{span_time};
	
    }
    $num_ifos = scalar keys %ifos;
}
my $int_window = floor($stretch_window / $span_time);

# iterate over all SFTs
my @num_sfts;
my @obs_time;
my @weights;
foreach my $path (keys %sfts) {
    
    # round SFT start time to nearest multiple of SFT baseline
    my $int_start = floor(($sfts{$path}->{start_time} - $min_start) / $span_time);
    
    # calculate duty cycle weights of SFT
    my $weight = $min_mean_psd / $sfts{$path}->{mean_psd};

    # iterate over all possible windows this SFT falls into
    for (my $i = List::Util::max($int_start - $int_window + 1, 0); $i <= $int_start; ++$i) {
	
	# add to number of SFTs
	++$num_sfts[$i];
	
	# add to observation time
	$obs_time[$i] += $span_time;
	
	# add weight to weighted duty cycle array
	$weights[$i] += $weight;
	
    }

}

# find the stretch with the maximal weight
my $stretch_index = index_of { $_[0] > $_[1] } @weights;
my $stretch_weight = $weights[$stretch_index] / ($num_ifos * $int_window);

# deduce the stretch minimum and maximum start times
my $stretch_min_start = $stretch_index * $span_time + $min_start;
my $stretch_max_start = $stretch_min_start + $stretch_window;

# find the stretch start and end times, and number of SFTs (from each IFO)
my ($stretch_start_time, $stretch_end_time);
my %stretch_num_sfts;
foreach my $path (keys %sfts) {
	
    my $start = $sfts{$path}->{start_time};
    my $end = $start + $span_time;
    
    if ($stretch_min_start <= $start && $start <= $stretch_max_start) {
	
	++$stretch_num_sfts{$sfts{$path}->{ifo}};

	if (!defined($stretch_start_time) || $start < $stretch_start_time) {
	    $stretch_start_time = $start;
	}

	if (!defined($stretch_end_time) || $end > $stretch_end_time) {
	    $stretch_end_time = $end;
	}

    }

}
my $stretch_num_sfts = List::Util::sum(values %stretch_num_sfts);

# calculate the stretch span and observation time
my $stretch_span_time = $stretch_end_time - $stretch_start_time;
my $stretch_obs_time = $stretch_num_sfts * $span_time / $num_ifos;

# write setup XML file
my @xml = (
	   'sft:ifos'           => join(' ', sort keys %stretch_num_sfts),
	   'sft:span_time'      => $span_time,
	   'stretch:start_time' => $stretch_start_time,
	   'stretch:end_time'   => $stretch_end_time,
	   'stretch:span_time'  => $stretch_span_time,
	   'stretch:weight'     => $stretch_weight,
	   'stretch:num_sfts'   => $stretch_num_sfts,
	   'stretch:obs_time'   => $stretch_obs_time,
	   );
foreach my $ifo (keys %stretch_num_sfts) {
    push @xml, "stretch:num_sfts_${ifo}" => $stretch_num_sfts{$ifo};
}
write_sft_stretch_xml @xml;

exit 0;
