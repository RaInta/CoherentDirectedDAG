#!/usr/bin/perl
#$Id: AddSFTInfoToDatabase.pl,v 1.5 2014/06/06 17:01:58 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;

# read existing SFT database
my %sfts;
read_sft_db \%sfts;

# read SFT information from output files
foreach my $outfile (glob "get_sft_info.out.*") {

    # open file
    open OUT, "$outfile" or die "Couldn't open '$outfile': $!";

    # iterate over SFT paths and information
    while (my $line = <OUT>) {
	chomp $line;

	# get path and information
	my ($path, @info) = split /\s+/, $line;

	# check that SFT exists in database
	die "'$path' does not exist in the database"
	    if !defined($sfts{$path});

	# add information to hash
	foreach my $info (@info) {
	    my ($name, $value) = split /=/, $info;
	    $sfts{$path}->{$name} = $value;
	}

    }

    # close file
    close OUT;

}

# write updated SFT database
write_sft_db \%sfts;

exit 0;
