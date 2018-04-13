#!/usr/bin/perl
#$Id: CollateSearchResults.pl,v 1.18 2014/06/15 13:53:08 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use File::Spec;
use POSIX ();

# Get timing statistics
my $start = time;

# read setup XMLs
my ($start_freq, $search_band, $span_time, $ul_band);
read_setup_xmls 
    'search:freq'      => \$start_freq, 
    'search:band'      => \$search_band,
    'search:span_time' => \$span_time,
    'upper_limit:band' => \$ul_band;

# read search bands, veto bands, and upper limit bands
my %search_bands;
read_search_bands_db \%search_bands;
my %veto_bands;
read_veto_bands_db \%veto_bands;

# read IFO job vetoes if they exist
my %ifo_v_jobs;
if (-f "../../ifo_v_jobs.txt") {
    open FILE, "../../ifo_v_jobs.txt" or die "Couldn't open 'ifo_v_jobs.txt': $!";
    while (<FILE>) {
        chomp;
        $ifo_v_jobs{$_} = 1;
    }
    close FILE;
    print "Vetoing jobs in ifo_v_jobs.txt:\n  ";
    foreach (sort { $a <=> $b } keys %ifo_v_jobs) {
        print " $_";
    }
    print "\n";
}

# create upper limit bands
my %ul_bands;
my $num_ul_bands = POSIX::ceil($search_band / $ul_band);
for (my $job = 0; $job < $num_ul_bands; ++$job) {
    $ul_bands{$job}->{job}  = $job;
    $ul_bands{$job}->{freq} = $start_freq + $job*$ul_band;
    $ul_bands{$job}->{band} = $ul_band;
}

# reset the loudest nonvetoed template
foreach (values %search_bands) {
    $_->{loudest_nonvetoed_template} = undef;
}
foreach (values %ul_bands) {
    $_->{loudest_nonvetoed_template} = undef;
}

# iterate over search jobs
my %failed;
my $vetoed = 0;
my $count1 = 0;
my $count2 = 0;
my $count3 = 0;
STDOUT->autoflush(1);
print "Processed (vetoed) jobs:";
foreach my $job (keys %search_bands) {

    # job subdirectory
    my $subdir = $search_bands{$job}->{subdir};

    # check job has been submitted
    if (-e "$subdir/search.sub.$job") {
	push @{$failed{'job not submitted'}}, $job;
	next;
    }

    ## check job files are all present
    #if (!(-s "$subdir/condor.out.$job" &&
    #      -z "$subdir/condor.err.$job" &&
    #      -s "$subdir/search.log.$job" &&
    #      -s "$subdir/search_results.txt.$job" &&
    #      -s "$subdir/search_histogram.txt.$job"))
    #{
    #    push @{$failed{'files are missing'}}, $job;
    #    next;
    #}
    
    # check search.log.$job
    {
	my $line;
	
	# open file
	open FILE, "$subdir/search.log.$job" or die "Couldn't open '$subdir/search.log.$job': $!";
	
	# get first few and last few lines
	$search_bands{$job}->{num_templates} = undef;
	while (<FILE>) {
	    chomp;
	    $line = $_ if length($_) > 0;
	    
	    # deduce number of templates
	    if ($line =~ /\[debug\]: Counting spindown lattice templates \.\.\. (\d+)$/) {
		$search_bands{$job}->{num_templates} = $1;
		
		# skip to near end of file
		seek FILE, -500, 2;
			
	    }
	    
	}
	close FILE;

	# check number of templates
	if (!defined($search_bands{$job}->{num_templates})) {
	    push @{$failed{'no number of templates in search.log.$job'}}, $job;
	    next;
	}
		
	# check last line
	if (!($line =~ /\[debug\]: Freeing Doppler grid \.\.\. done/)) {
	    push @{$failed{'no last line of search.log.$job'}}, $job;
	    next;
	}

    }
	    
    # check search_results.txt.$job and search_histogram.txt.$job
    foreach my $file (qw(results histogram)) {
	
	my $line;
		
	# open file
	open FILE, "$subdir/search_$file.txt.$job" or die "Couldn't open '$subdir/search_$file.txt.$job': $!";
	
	# get last few lines
	seek FILE, -500, 2;
	while (<FILE>) {
	    chomp;
	    $line = $_ if length($_) > 0;
	}
	close FILE;
	
	# check last line
	if (!($line =~ /^%DONE$/)) {
	    push @{$failed{'no last line of search_'.$file.'.txt.$job'}}, $job;
	}
		
    }

    # skip event processing if job is IFO vetoed
    if (exists $ifo_v_jobs{$job}) {
        ++$vetoed;
        next;
    }

    # skip event processing if whole job is fscan vetoed
    my $vetoed_whole_job = 0;
    foreach my $key (keys %veto_bands) {
        if ($search_bands{$job}->{freq} >= $veto_bands{$key}->{freq} && $search_bands{$job}->{freq} + $search_bands{$job}->{band} <= $veto_bands{$key}->{freq} + $veto_bands{$key}->{band}) {
            $vetoed_whole_job = 1;
            last;
        }
    }
    if ($vetoed_whole_job) {
	$search_bands{$job}->{num_templates_vetoed} = 0;
        ++$vetoed;
        next;
    }
    
    # open search_results.txt.$job
    open FILE, "$subdir/search_results.txt.$job" or die "Couldn't open 'search_results.txt.$job': $!";

    # process the events
    $search_bands{$job}->{num_templates_vetoed} = 0;
    $search_bands{$job}->{nonvetoed_candidates} = 0;
    while (<FILE>) {
	chomp;
	next if /^%/;
	
	# parse the result line
	my $template = parse_CFSv2_output_line $_;
	
	# get the band covered by the template
	($template->{cover_freq}, $template->{cover_band}) = template_covering_band $template, $span_time;
	
        # check fscan veto
	my $template_vetoed = 0;
	foreach my $key (keys %veto_bands) {
	    if (do_bands_intersect($template->{cover_freq}, $template->{cover_band}, $veto_bands{$key}->{freq}, $veto_bands{$key}->{band})) {
		$template_vetoed = 1;
		last;
	    }
	}
	next if $template_vetoed;
	
        # check IFO consistency veto
        if ($template->{twoFH1} > $template->{twoF} || $template->{twoFL1} > $template->{twoF}) {
            ++$search_bands{$job}->{num_templates_vetoed};
            $template_vetoed = 1;
        }
        next if $template_vetoed;

	# count nonvetoed recorded candidates in search job
	++$search_bands{$job}->{nonvetoed_candidates};

	# record the loudest non-vetoed template for search and upper limit bands
 	if (!defined($search_bands{$job}->{loudest_nonvetoed_template}) || $search_bands{$job}->{loudest_nonvetoed_template}->{twoF} < $template->{twoF}) {
	    $search_bands{$job}->{loudest_nonvetoed_template} = {%{$template}};
	}
	foreach my $key (keys %ul_bands) {
	    if (do_bands_intersect($template->{freq}, 0.0, $ul_bands{$key}->{freq}, $ul_bands{$key}->{band})) {
		if (!defined($ul_bands{$key}->{loudest_nonvetoed_template}) || $ul_bands{$key}->{loudest_nonvetoed_template}->{twoF} < $template->{twoF}) {
		    $ul_bands{$key}->{loudest_nonvetoed_template} = {%{$template}};
		}
	    }
	}		

    }
    close FILE;
    
    # count if all candidates were completely vetoed
    if (!defined($search_bands{$job}->{loudest_nonvetoed_template})) {
	++$vetoed;
    }
    # see if IFO veto kills whole job
    if ($search_bands{$job}->{nonvetoed_candidates} < $search_bands{$job}->{num_templates_vetoed}) {
	$ifo_v_jobs{$job} = 1;
	++$vetoed;
    }

}
continue {
    
    # progress update
    ++$count1;
    if ($count1 >= 200) {
	$count1 = 0;
	++$count2;
	print "\n  " if ($count3 == 0);
	printf " %5i(%5i)", $count2 * 200, $vetoed;
	++$count3;
	$count3 = 0 if ($count3 == 5);
    }

}
print "\n  " if ($count3 == 0);
printf " %5i(%5i)\n", ($count2 * 200) + $count1, $vetoed;
STDOUT->autoflush(0);

# print any failed jobs
if (scalar(keys %failed) == 0) {
    print "All jobs were successfully processed.\n";
}
else {
    print "Some jobs could not be processed:\n";
    foreach (sort keys %failed) {
	print "   Reason: $_";
	my $count = 0;
	foreach (@{$failed{$_}}) {
	    print "\n     " if ($count == 0);
	    printf " %5i", $_;
	    ++$count;
	    $count = 0 if ($count == 10);
	}
	print "\n" if ($count != 0);
    }
}

# write search and upper limit bands
write_search_bands_db \%search_bands;
write_ul_bands_db \%ul_bands;
# write IFO vetoed jobs file
open FILE, ">../../ifo_v_jobs.txt" or die "Couldn't open ifo_v_jobs.txt";
foreach my $name (sort { $a <=> $b } keys %ifo_v_jobs) {
    print FILE "$name\n";
}
close FILE;

# Merge IFO-vetoed bands with previous veto bands
foreach my $job (sort { $a <=> $b } keys %ifo_v_jobs) {
    my %overlaps;
    my $hikey;
    my $lokey = '-1';
    # Construct list of f-vetoed bands that overlap the i-vetoed band
    foreach my $key (sort { $a <=> $b } keys %veto_bands) {
       next if (!do_bands_intersect($veto_bands{$key}->{freq}, $veto_bands{$key}->{band}, $search_bands{$job}->{freq}, $search_bands{$job}->{band}));
       $overlaps{$key} = $veto_bands{$key};
       $hikey = $key;
       if ($lokey == '-1') {
           $lokey = $key;
       }
    }
    # If no overlap, just add the search band to the veto bands
    if (keys (%overlaps) == 0) {
	my $key;
	my $veto = {};
	$key = $search_bands{$job}->{freq};
	$veto->{freq} = $key;
	$veto->{band} = $search_bands{$job}->{band};
	$veto->{power} = 0;
	$veto_bands{$key} = $veto;
	next;
    }
    # If IFO-vetoed band goes lower than lowest F_vetoed band...
    if ($search_bands{$job}->{freq} < $veto_bands{$lokey}->{freq}) {
       # Stretch lowest F-vetoed band down to match
       $veto_bands{$lokey}->{band} += $veto_bands{$lokey}->{freq} - $search_bands{$job}->{freq};
       $veto_bands{$lokey}->{freq} = $search_bands{$job}->{freq};
    }
    # If I-vetoed band goes higher than highest F-vetoed band...
    if ($search_bands{$job}->{freq} + $search_bands{$job}->{band} > $veto_bands{$hikey}->{freq} + $veto_bands{$hikey}->{band}) {
       # Stretch lowest F-vetoed band up to match
       $veto_bands{$lokey}->{band} = $search_bands{$job}->{freq} + $search_bands{$job}->{band} - $veto_bands{$lokey}->{freq};
    }
    # Else stretch lowest F-vetoed band to cover all overlapping ones
    else {
       $veto_bands{$lokey}->{band} = $veto_bands{$hikey}->{freq} + $veto_bands{$hikey}->{band} - $veto_bands{$lokey}->{freq};
    }
    # Delete all frequency bands but lowest.
    foreach my $key (keys %overlaps) {
       if ($key != $lokey) {
           delete $veto_bands{$key};
       }
    }
}
# Merge consecutive veto bands
my $prev = '-1';
foreach my $key (sort { $a <=> $b } keys %veto_bands) {
    my $foo = 0 + $veto_bands{$key}->{freq};
    my $foo = $veto_bands{$key}->{freq};
    if ($prev eq '-1') {
	$prev = $key;
	next;
    }
    # This needs to guard against floating-point truncation error
    if (abs(0 + $veto_bands{$key}->{freq} - $veto_bands{$prev}->{freq} - $veto_bands{$prev}->{band}) < 0.0000001) {
	$veto_bands{$prev}->{band} += $veto_bands{$key}->{band};
	delete $veto_bands{$key};
    }
    else {
	$prev = $key;
    }
}
# Rewrite veto bands database
write_veto_bands_db \%veto_bands;

my $diff = time - $start;
print "Time taken to collate (old version) was $diff seconds\n";

exit 0;
