#!/usr/bin/perl
#$Id: CollateTemplateDensities.pl,v 1.3 2011/09/28 15:38:00 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;

my %density;

# read template densities from output files
foreach my $outfile (glob "calc_template_density.out.*") {

    # get file contents file
    open OUT, "$outfile" or die "Couldn't open '$outfile': $!";
    chomp(my $line = <OUT>);
    close OUT;

    # get information
    my %info;
    foreach my $pair (split /\s+/, $line) {
	my ($name, $value) = split /=/, $pair;
	$info{$name} = $value;
    }
    
    # add information to hash
    foreach my $key (keys %info) {
	$density{$info{freq}}->{$key} = $info{$key};
    }

}

# write template densities
write_density_db \%density;

exit 0;
