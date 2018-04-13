#!/usr/bin/perl
# This just copies SFTs to your global/sfts directory
# Meant to be a stop-gap measure if you've failed the
# MakeSearchJobs step because of I/O conditions

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use POSIX ();
use File::Spec;

use constant MD5SUM_PREFIX_REGEX  => '^([0-9a-fA-F]{32}\s\*)(.+)$';

# read setup XMLs
my ($span_time, $start_time);
my ($num_sfts);
read_setup_xmls 
    'stretch:start_time' => \$start_time,
    'stretch:span_time'  => \$span_time,
    'stretch:num_sfts'   => \$num_sfts,

# read SFT database
my %sfts;
read_sft_db \%sfts;


# get location of global SFTs
my $global_sfts = GLOBAL_DIR('sfts');
assert_directory $global_sfts;

chdir $global_sfts;

# get stretch SFTs
my @stretch;
foreach my $path (keys %sfts) {
    
    my $start = $sfts{$path}->{start_time};
    my $end = $start + $sfts{$path}->{span_time};
    
    # skip if SFT does not fall fully within stretch
    next if !($start_time <= $start && $end <= ($start_time + $span_time));
    
    # add to stretch SFTs
    push @stretch, $path;
    
}

# check all the SFTs were found
die "Didn't find all SFTs claimed to be in stretch: $num_sfts != @{[scalar @stretch]}"
    if ($num_sfts != @stretch);

# get existing SFTs in current directory
my %existing_sfts;
foreach my $name (glob '*.sft') {
    $existing_sfts{$name}->{needed} = 0;
}

# get existing MD5 checksums
if ( -f 'md5sums.txt') {
    open FILE, "md5sums.txt" or die "Couldn't open 'md5sums.txt': $!";
    while (<FILE>) {
	chomp;
	if (/@{[MD5SUM_PREFIX_REGEX]}/) {
	    $existing_sfts{$2}->{md5sum_prefix} = $1;
	}
	else {
	    die "Couldn't parse ms5sum line '$_' in 'md5sums.txt'";
	}
    }
    close FILE;
}


# check that all the stretch SFTs are present
for (my $i = 0; $i < @stretch; ++$i) {
    my $path = $stretch[$i];
    my $name = $sfts{$path}->{name};
    
    printf "Processing $name (%i of %i): ", $i + 1, scalar @stretch;
    
    # copy the SFT
    if (!defined($existing_sfts{$name})) {
	print "copying ";
	!system "rsync --checksum $path $name" or die "Couldn't copy '$path': $!";
    }
    
    # validate and compute the checksum of the SFT
    if (!defined($existing_sfts{$name}->{md5sum_prefix})) {
	
	print "validating ";
	my $SFTvalidate = abs_exec_path 'lalapps_SFTvalidate';
	!system "$SFTvalidate $name" or die "Couldn't validate '$name': $!";
	
	print "checksum ";
	open PIPE, "md5sum --binary $name | " or die "Couldn't md5sum '$name': $!";
	chomp($_ = <PIPE>);
	close PIPE;
	if (/@{[MD5SUM_PREFIX_REGEX]}/) {
	    $existing_sfts{$2}->{md5sum_prefix} = $1;
	}
	else {
	    die "Couldn't parse md5sum line '$_'";
	}
	
    }
    
    print "done\n";
    
    # mark the SFT as needed
    $existing_sfts{$name}->{needed} = 1;
    
}


# check for any extra or unneeded SFTs
foreach my $name (keys %existing_sfts) {
    if (!$existing_sfts{$name}->{needed}) {
	print "Processing $name: removing ";
	!system "rm -f $name" or die "Couldn't remove '$name': $!";
	delete $existing_sfts{$name};
	print "done\n";
    }
}

# write MD5 checksums
open FILE, ">md5sums.txt" or die "Couldn't open 'md5sums.txt': $!";
foreach my $name (sort keys %existing_sfts) {
    print FILE "$existing_sfts{$name}->{md5sum_prefix}$name\n";
}
close FILE;

chdir INITIAL_DIR;

exit 0;
