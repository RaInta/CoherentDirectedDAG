#!/usr/bin/perl
#$Id: CleanResults.pl,v 1.3 2013/10/23 20:27:55 ra.inta Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use File::Spec;
use POSIX ();
use Cwd;

# read setup XMLs
my ($start_freq, $search_band, $span_time, $ul_band);
read_setup_xmls 
    'search:freq'      => \$start_freq, 
    'search:band'      => \$search_band,
    'search:span_time' => \$span_time,
    'upper_limit:band' => \$ul_band;

# Create array to hold all candidate job numbers
my @jobArray;
    
# R.I.: Optional: take a job number as an input parameter 
if ($#ARGV +1 ){
        my $numArg = $#ARGV + 1;
        foreach my $argnum (0 .. $#ARGV) {
		#print "Jobs manually added from command-line: $ARGV[$argnum]";
		push(@jobArray, $ARGV[$argnum]);
        }
	print "$numArg jobs manually added from command-line: @jobArray \n";
}



# TODO: Automatically bzip2 results files?

my $initialdir = getcwd;                               # R.I.: Might want to change directory from main (INITIAL_DIR)

# read search bands, veto bands, and upper limit bands
my %search_bands;
read_search_bands_db \%search_bands;
my %veto_bands;
read_veto_bands_db \%veto_bands;

# Change directory to jobs/search 
chdir "jobs/search";

# read manual job vetoes if they exist
my %man_v_jobs;
if (-f "../../man_v_jobs.txt") {
    open FILE, "../../man_v_jobs.txt" or die "Couldn't open 'man_v_jobs.txt': $!";
    while (<FILE>) {
        chomp;
        $man_v_jobs{$_} = 1;
	push(@jobArray, $_);
    }
    close FILE;
    #print "Manually vetoing jobs in man_v_jobs.txt:\n  ";
    #foreach (keys %man_v_jobs) {
    #        print " $_";
    #}
    #print "\n";
}


# create upper limit bands
my %ul_bands;
my $num_ul_bands = POSIX::ceil($search_band / $ul_band);
for (my $job = 0; $job < $num_ul_bands; ++$job) {
    $ul_bands{$job}->{job}  = $job;
    $ul_bands{$job}->{freq} = $start_freq + $job*$ul_band;
    $ul_bands{$job}->{band} = $ul_band;
}



## reset the loudest (nonvetoed) template
#foreach (values %search_bands) {
#    $_->{loudest_template} = undef;
#    $_->{loudest_nonvetoed_template} = undef;
#}
#foreach (values %ul_bands) {
#    $_->{loudest_template} = undef;
#    $_->{loudest_nonvetoed_template} = undef;
#}

# iterate over search jobs
my %failed;
my $vetoed = 0;
my $count1 = 0;
my $count2 = 0;
my $count3 = 0;
STDOUT->autoflush(1);
#print "Processed (vetoed) jobs:  ";
#foreach my $job (keys %search_bands) {  ## R.I.: We don't want to loop over all jobs so this is commented out.


foreach my $inputJob (@jobArray){

	print "############### Processing job: $inputJob                      ###############\n";
	# job subdirectory
	my $subdir = $search_bands{$inputJob}->{subdir};

	# check job has been submitted
	if (-e "$subdir/search.sub.$inputJob") {
	push @{$failed{'job not submitted'}}, $inputJob;
	next;
	}

	# check file for jobname exists
	unless (-e "$subdir/search_results.txt.$inputJob") {
	 die "Warning! No search_results.txt.$inputJob file found. Please enter a valid job number.";
	 }
	 
	# check job files are all present
	if (!(-s "$subdir/condor.out.$inputJob" &&
	  -z "$subdir/condor.err.$inputJob" &&
	  -s "$subdir/search.log.$inputJob" &&
	  -s "$subdir/search_results.txt.$inputJob" &&
	  -s "$subdir/search_histogram.txt.$inputJob"))
	{
	push @{$failed{'files are missing'}}, $inputJob;
	next;
	}
	    
	# check search.log.$inputJob
	{
	my $line;
		
	# open file
	open FILE, "$subdir/search.log.$inputJob" or die "Couldn't open '$subdir/search.log.$inputJob': $!";

	# get first few and last few lines
	$search_bands{$inputJob}->{num_templates} = undef;
	while (<FILE>) {
	    chomp;
	    $line = $_ if length($_) > 0;
	    
	    # deduce number of templates
	    if ($line =~ /\[debug\]: Counting spindown lattice templates \.\.\. (\d+)$/) {
		$search_bands{$inputJob}->{num_templates} = $1;
		
		# skip to near end of file
		seek FILE, -500, 2;
			
	    }
	    
	}

	close FILE;  # search_bands file

	# check number of templates
	if (!defined($search_bands{$inputJob}->{num_templates})) {
	    push @{$failed{'no number of templates in search.log.$inputJob'}}, $inputJob;
	    next;
	}
		
	# check last line
	if (!($line =~ /\[debug\]: Freeing Doppler grid \.\.\. done/)) {
	    push @{$failed{'no last line of search.log.$inputJob'}}, $inputJob;
	    next;
	}

	}
	    
	# check search_results.txt.$inputJob and search_histogram.txt.$inputJob
	foreach my $file (qw(results histogram)) {

		my $line;
		
		# open file
		open FILE, "$subdir/search_$file.txt.$inputJob" or die "Couldn't open '$subdir/search_$file.txt.$inputJob': $!";

		# get last few lines
		seek FILE, -500, 2;
		while (<FILE>) {
		    chomp;
		    $line = $_ if length($_) > 0;
		}
		close FILE;

		# check last line
		if (!($line =~ /^%DONE$/)) {
		    push @{$failed{'no last line of search_'.$file.'.txt.$inputJob'}}, $inputJob;
		}
		
	}

	## skip event processing if job is manually vetoed
	#if (exists $man_v_jobs{$inputJob}) {
	#    ++$vetoed;
	#    next;
	#}

	## skip event processing if whole job is fscan vetoed
	my $vetoed_whole_job = 0;
	foreach my $key (keys %veto_bands) {
	    if ($search_bands{$inputJob}->{freq} >= $veto_bands{$key}->{freq} && $search_bands{$inputJob}->{freq} + $search_bands{$inputJob}->{band} <= $veto_bands{$key}->{freq} + $veto_bands{$key}->{band}) {
		$vetoed_whole_job = 1;
		last;
	    }
	}
	if ($vetoed_whole_job) {
	    # actually this should just count candidates, not all templates in job
	    $search_bands{$inputJob}->{num_templates_vetoed} = $search_bands{$inputJob}->{num_templates};
	    ++$vetoed;
	    next;
	}

	# open search_results.txt.$inputJob
	open FILE, "$subdir/search_results.txt.$inputJob" or die "Couldn't open 'search_results.txt.$inputJob': $!";
	mkdir "$initialdir/cleanedResults";
	my $line;



	# Make cleaned candidate file. Note this creates a folder in your initial search directory to put cleaned files in. 
	open CLEAN_FILE, ">$initialdir/cleanedResults/cleaned_candidate.txt.$inputJob" or die "Couldn't open 'cleaned_candidate.txt': $!";
	my $cleanLine;
	my $headerLine;

	# process the events
	$search_bands{$inputJob}->{num_templates_vetoed} = 0;
	while (<FILE>) {
		chomp;
		$cleanLine = $_;
		#$headerLine = $_ if /%/;    # R.I.: Commenting this out to bug-test
		#print CLEAN_FILE "$headerLine\n";             # R.I.: This is to preserve the header information (%%) from the results file 
		if (substr($cleanLine, 0, 1) == "%"){
			print CLEAN_FILE "$cleanLine\n";
		
		}
		next if /^%/;
		$cleanLine = $_;

		# parse the result line
		my $template = parse_CFSv2_output_line $_;


		# get the band covered by the template
		($template->{cover_freq}, $template->{cover_band}) = template_covering_band $template, $span_time;

		# possibly veto the template
		my $template_vetoed = 0;
		# check IFO consistency veto 
		if ($template->{twoFH1} > $template->{twoF} || $template->{twoFL1} > $template->{twoF}) {
		    ++$search_bands{$inputJob}->{num_templates_vetoed};
		    $template_vetoed = 1;
		}
		next if $template_vetoed;
		# check fscan veto
		foreach my $key (keys %veto_bands) {
		    if (do_bands_intersect($template->{cover_freq}, $template->{cover_band}, $veto_bands{$key}->{freq}, $veto_bands{$key}->{band})) {
			++$search_bands{$inputJob}->{num_templates_vetoed};
			$template_vetoed = 1;
			#print "Template not OK, freq: $template->{cover_freq}\n";
			#print CLEAN_FILE "################BAD TEMPLATE###########\n";
			#print CLEAN_FILE "$line\n";
			#print CLEAN_FILE "Template vetoed: $template_vetoed \n";
			#print CLEAN_FILE "######################################\n";
			#print "Veto band number: $key";
			#last;
		    }
		    #else {
		    #    print CLEAN_FILE "$line\n";
		    #    #print CLEAN_FILE "Template freq: $template->{cover_freq}\n";
		    #    #print CLEAN_FILE "Template vetoed: $template_vetoed \n";
		    #    #foreach my $cleankey (keys %search_bands){
		    #    	#print CLEAN_FILE $search_bands{$cleankey}->{freq};
		    #}


		if ($vetoed_whole_job){
			print CLEAN_FILE "Entire job was vetoed\n";
		}
		}
		next if $template_vetoed;
		if ($template_vetoed == 0){
			print CLEAN_FILE "$cleanLine\n";
		}
	} # Event processing

	print "############### Total number of templates: $search_bands{$inputJob}->{num_templates}   ###############\n";
	print "############### Total number of vetoed templates: $search_bands{$inputJob}->{num_templates_vetoed}   #############\n";


	print CLEAN_FILE "%Total number of templates: $search_bands{$inputJob}->{num_templates}\n";
	print CLEAN_FILE "%Total number of vetoed templates: $search_bands{$inputJob}->{num_templates_vetoed}\n";
	close CLEAN_FILE;                                                                                      

	close FILE;     # Search results file

	# count if all candidates were completely vetoed
	if (!defined($search_bands{$inputJob}->{loudest_nonvetoed_template})) {
		++$vetoed;
	}
} # Close foreach @jobArray element

#continue {
#    
#    # progress update
#    ++$count1;
#    if ($count1 >= 200) {
#	$count1 = 0;
#	++$count2;
#	print "\n  " if ($count3 == 0);
#	printf " %5i(%5i)", $count2 * 200, $vetoed;
#	++$count3;
#	$count3 = 0 if ($count3 == 5);
#    }
#
#}
#print "\n  " if ($count3 == 0);
#printf " %5i(%5i)\n", ($count2 * 200) + $count1, $vetoed;
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


exit 0;
