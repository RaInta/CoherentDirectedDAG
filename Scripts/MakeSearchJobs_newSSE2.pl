#!/usr/bin/perl
#$Id: MakeSearchJobs.pl,v 1.6 2012/03/20 14:27:09 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use Getopt::Long;
use POSIX ();
use File::Spec;

use constant SRCH_JOBS_PER_SUBDIR => 250;
use constant MD5SUM_PREFIX_REGEX  => '^([0-9a-fA-F]{32}\s\*)(.+)$';

## check current directory is empty of previous job files
#assert_no_files_matching 'condor.*', 'search.*';

# read setup XMLs
my ($freq, $band, $span_time, $start_time);
my ($num_sfts, $compute_cost);
read_setup_xmls 
    'search:freq'        => \$freq, 
    'search:band'        => \$band,
    'stretch:start_time' => \$start_time,
    'stretch:span_time'  => \$span_time,
    'stretch:num_sfts'   => \$num_sfts,
    'compute:cost'       => \$compute_cost;

# parse options
my $job_hours;
my $account_group;
my $account_user;

GetOptions (
    'job-hours=f'      => \$job_hours,
    'account-group=s'  => \$account_group,
    'account-user=s'   => \$account_user,
    );

assert_strictly_positive '--job-hours', $job_hours;

# read SFT database
my %sfts;
read_sft_db \%sfts;

# read template densities
my %density;
read_density_db \%density;

# calculate the number of templates per job
my $job_templates = POSIX::ceil(($job_hours * 3600.0) / ($num_sfts * $compute_cost));

# make a list of sorted frequencies for interpolation
my @density_freq = sort { $a <=> $b } keys %density;

# create frequency bands
my %search_bands;
my $job = 0;
my $job_freq = $freq;
while ($job_freq < $freq + $band) {

    # get largest interpolation frequency smaller than job frequency
    my $i = grep { $_ <= $job_freq } @density_freq;

    # get linear interpolation points
    my $f1 = $density_freq[$i-1];
    my $f2 = $f1 + $density{$density_freq[$i-1]}->{band};
    my $d1 = $density{$f1}->{density};
    my $d2 = $density{$f2}->{density};

    # calculate linear interpolation
    my $m = ($d2 - $d1) / ($f2 - $f1);
    my $c = ($f2*$d1 - $f1*$d2) / ($f2 - $f1);

    # calculate interpolated density
    my $job_density = $c + $m * $job_freq;

    # calculate frequency band for this job
    my $search_band = $job_templates / $job_density;
    if ($job_freq + $search_band >= $freq + $band) {
	$search_band = $freq + $band - $job_freq;
    }

    # set job number and frequency range
    $search_bands{$job}->{job} = $job;
    $search_bands{$job}->{freq} = $job_freq;
    $search_bands{$job}->{band} = $search_band;

    # set job subdirectory
    $search_bands{$job}->{subdir} = sprintf("%i", POSIX::floor($job / SRCH_JOBS_PER_SUBDIR));

    # advance
    ++$job;
    $job_freq += $search_band;
    
}

# check that last job is not too small
if ($job > 1 && $search_bands{$job-1}->{band} / $search_bands{$job-2}->{band} < 0.2) {
    $search_bands{$job-2}->{band} += $search_bands{$job-1}->{band};
    delete $search_bands{$job-1};
}

# convert to fixed precision
foreach my $job (keys %search_bands) {
    $search_bands{$job}->{freq} = sprintf "%0.12f", $search_bands{$job}->{freq};
    $search_bands{$job}->{band} = sprintf "%0.12f", $search_bands{$job}->{band};
}


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


# create condor submission files in subdirectories
foreach my $job (keys %search_bands) {

    my $freq = $search_bands{$job}->{freq};
    my $band = $search_bands{$job}->{band};

    assert_directory $search_bands{$job}->{subdir};

    chdir $search_bands{$job}->{subdir};

    condor_sub_file "search.sub.$job",
        'accounting_group'  => "$account_group",
        'accounting_group_user'   => "$account_user",
	'executable'     => 'Search_newSSE2.pl',
	'arguments'      => "--job $job --freq $freq --band $band",
	'output'         => "condor.out.$job",
	'error'          => "condor.err.$job",
	'queue'          => 1;

    chdir INITIAL_DIR;

}


# write search bands
write_search_bands_db \%search_bands;

# print number of jobs
printf "Created %i search jobs\n", scalar keys %search_bands;

# Write out total number of jobs to file 
open FILE, ">total_job_number.txt" or die "Couldn't open 'total_job_number.txt': $!";
   print FILE scalar keys %search_bands;
close FILE;

exit 0;
