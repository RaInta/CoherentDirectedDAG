#!/usr/bin/perl
#$Id: AddSFTsToDatabase.pl,v 1.3 2011/09/28 15:37:59 owen Exp $

use strict;
use File::Basename;
use lib dirname($0);
use CasACommon;
use File::Spec;


# read existing SFT database
my %sfts;
read_sft_db \%sfts, 'create';

# get SFT type of existing SFTs
my %sft;
if (defined(my $path = (keys %sfts)[0])) {
    $sft{type} = $sfts{$path}->{sft_type};
}

# read additional SFT paths from standard input
while (my $path = <STDIN>) {
    chomp $path;

    # remove protocol://server from beginning
    if ($path =~ s|^(\w+)://[^/]+/|/|) {
	die "'$1' protocol not supported" if ($1 ne 'file');
    }

    # parse filename
    parse_sft_filename $path, \%sft;

     # check for existing SFT
    die "'$sft{name}' is already in the database" if defined($sfts{$path});

    # only handle single SFTs
    die "'$sft{name}' is not a single SFT file" if ($sft{num} != 1);

    # add SFT information to hash
    $sfts{$path}->{path} = $path;
    $sfts{$path}->{name} = $sft{name};
    $sfts{$path}->{ifo} = $sft{ifo};
    $sfts{$path}->{sft_type} = $sft{type};
    $sfts{$path}->{start_time} = $sft{start};
    $sfts{$path}->{span_time} = $sft{span};
    
}

# write new SFT database
write_sft_db \%sfts;

exit 0;
