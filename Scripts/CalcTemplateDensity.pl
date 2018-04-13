#!/usr/bin/perl
#$Id: CalcTemplateDensity.pl,v 1.6 2014/06/06 17:01:59 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use Getopt::Long;
use File::Spec;
use XML::Twig;

# parse options
my ($freq, $band, $step, $job, $jobs, $outfile);
GetOptions 
    'freq=f' => \$freq, 
    'band=f' => \$band,
    'step=f' => \$step,
    'job=i'  => \$job, 
    'jobs=i' => \$jobs, 
    'out=s'  => \$outfile;
assert_strictly_positive '--freq', $freq, '--band', $band, '--step', $step;
assert_positive          '--job',  $job;
assert_strictly_positive '--jobs', $jobs;
assert_strictly_less     '--job',  $job, '--jobs', $jobs;
assert_no_file_exists    '--out', $outfile;

# read setup XMLs
my ($spindown_age, $min_braking, $max_braking, $span_time, $max_mismatch);
read_setup_xmls 
    'target:spindown_age' => \$spindown_age,
    'target:min_braking'  => \$min_braking,
    'target:max_braking'  => \$max_braking,
    'search:span_time'    => \$span_time,
    'search:max_mismatch' => \$max_mismatch;

# work out job frequency
my $jobfreq = $freq + $step * $job;

## calculate number of templates and parse output
my @xml = run_exec_output 'lalapps_LatticeTilingCount', {
    #'age-braking'  => "$jobfreq,$band,6,1,$spindown_age,$min_braking,$max_braking",
    'age-braking'  => "6,1,$jobfreq,$band,$spindown_age,$min_braking,$max_braking",
    'time-span'    => $span_time,
    'max-mismatch' => $max_mismatch,
    'lattice'      => 'an-star',  # Anstar
    'metric'       => 'spindown',   # spindown
    #'only-count'   => 'yes',
    #'output'       => '/dev/stdout'
};


#my $twig = XML::Twig->new();
#$twig->safe_parse("@xml") or die "XML::Twig->safe_parse failed: $!";

## get the number of templates
#my $templates = $twig->root->first_child('template_count')->text;
#my $templates = $twig->root->text;
my $templates = $xml[0];
#$templates =~ s/\s//g;

$templates *= 1.0;

# calculate the density of templates in frequency;
my $density = $templates / $band;

# output the frequency band and number of templates
open OUT, ">$outfile" or die "Couldn't open '$outfile': $!";
print OUT "freq=$jobfreq band=$step density=$density\n";
close OUT;

exit 0;
