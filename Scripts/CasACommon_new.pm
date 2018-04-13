#$Id: CasACommon.pm,v 1.10 2012/12/22 02:32:48 owen Exp $
use strict;

# common routines
package CasACommon;
require Exporter;

# base modules
use Carp;
use Switch;
use File::Spec;
use Cwd qw(getcwd abs_path);
use List::Util ();

# Get rid of library directories causing issues.
#no lib "/usr/local/lib/perl/5.10.1";
#no lib "/usr/local/share/perl/5.10.1";
#no lib "/home/ra/perl5/lib/perl5/x86_64-linux-gnu-thread-multi";

# CPAN modules
use File::Basename;
use lib dirname($0);
use lib "$ENV{HOME}/perl5/lib/perl5";
use IO::File;
use IO::Compress::Bzip2;
use IO::Uncompress::Bunzip2;
use XML::Simple;
use XML::Twig;

# exports
our @ISA = qw(Exporter);
our @EXPORT = qw(
		 INITIAL_DIR
		 LOCAL_DIR                     GLOBAL_DIR
		 LAL_DATA_PATH
		 FSTAT_DTERMS
		 SRCH_HISTOGRAM
                 UL_MISM_HISTOGRAM             UL_HIST_BINWIDTH
		 index_of
		 do_bands_intersect            is_band_contained_in
		 assert_strictly_positive      assert_positive
		 assert_strictly_less          assert_less
		 assert_file_exists            assert_no_file_exists
		 assert_files_matching         assert_no_files_matching
		 check_directory               assert_directory
		 parse_sft_filename
		 read_setup_xmls               write_setup_xml
		 write_sft_stretch_xml         write_comp_cost_xml
		 read_sft_db                   write_sft_db
		 read_density_db               write_density_db
		 read_veto_bands_db            write_veto_bands_db
		 read_search_bands_db          write_search_bands_db
		 read_ul_bands_db              write_ul_bands_db
		 abs_exec_path
		 ident_strings
		 run_exec                      run_exec_output
		 condor_sub_file
		 get_check_local_sfts
		 parse_CFSv2_output_line
		 template_covering_band
		 );

my ($initialdir, $scriptsdir, $resultsdir);

# constants
sub INITIAL_DIR       { $initialdir }
sub LOCAL_DIR         { File::Spec->catdir($resultsdir, 'local', @_) }
sub GLOBAL_DIR        { File::Spec->catdir($resultsdir, 'global', @_) }
sub LAL_DATA_PATH     { File::Spec->catdir($scriptsdir, 'production/share/lalpulsar', @_ ) }
# cut from default 16 to match with SSE2 fstat code
sub FSTAT_DTERMS      { 8 }
sub SRCH_HISTOGRAM    { File::Spec->catfile($resultsdir, 'search_histogram.txt') }
sub UL_MISM_HISTOGRAM { File::Spec->catfile($scriptsdir, 'upper_limit_mismatch_histogram.txt') }
sub UL_HIST_BINWIDTH  { 10 }

# files and paths
sub SETUP_XML        { File::Spec->catfile($resultsdir, 'search_setup.xml') }
sub SFT_STRETCH_XML  { File::Spec->catfile($resultsdir, 'optimal_sft_stretch.xml') }
sub COMP_COST_XML    { File::Spec->catfile($resultsdir, 'compute_cost.xml') }
sub SFT_DB           { File::Spec->catfile($resultsdir, 'sft_database.xml.bz2') }
sub DENSITY_DB       { File::Spec->catfile($resultsdir, 'template_density.xml') }
sub VETO_BANDS_DB    { File::Spec->catfile($resultsdir, 'veto_bands.xml') }
sub SRCH_BANDS_DB    { File::Spec->catfile($resultsdir, 'search_bands.xml.bz2') }
sub UL_BANDS_DB      { File::Spec->catfile($resultsdir, 'upper_limit_bands.xml') }
sub EXEC_PATH        { (
			$scriptsdir,
			File::Spec->catfile($scriptsdir, 'production/bin' )
			) }

# save initial directory
$initialdir = Cwd::abs_path(Cwd::getcwd());

# deduce scripts directory
$scriptsdir = Cwd::abs_path(dirname($0));

# deduce results directory
$resultsdir = INITIAL_DIR;
{
    my $common_len = 1;
    ++$common_len while (substr($scriptsdir, 0, $common_len) eq substr($resultsdir, 0, $common_len));
    while (! -f SETUP_XML) {
	$resultsdir = dirname($resultsdir);
	croak "Couldn't find @{[SETUP_XML]}" if (length($resultsdir) < $common_len);
    }
}

# print hostname if running as Condor job
foreach (keys %ENV) {
    if (/^_CONDOR/) {
	chomp(my $hostname = `hostname --short`);
	print '%' x 10, " Running under Condor on $hostname ", '%' x 10, "\n";
	last;
    }
}

return 1;


# get the index of the element selected by the function
sub index_of(&@) {

    my ($func, @list) = @_;

    $a = $list[0];
    my $i = 0;

    for (my $j = 1; $j < @_; ++$j) {
	$b = $list[$j];
	if (&{$func}($b, $a)) {
	    $a = $b;
	    $i = $j;
	}
    }

    return $i;

}

# do two bands/ranges intersect?
sub do_bands_intersect {

    my ($f1, $b1, $f2, $b2) = @_;

    return (List::Util::min($f1, $f1 + $b1) <= List::Util::max($f2, $f2 + $b2))
	&& (List::Util::min($f2, $f2 + $b2) <= List::Util::max($f1, $f1 + $b1));

}

# is first band/range contained in second band/range?
sub is_band_contained_in {

    my ($f1, $b1, $f2, $b2) = @_;

    return (List::Util::min($f1, $f1 + $b1) >= List::Util::min($f2, $f2 + $b2))
	&& (List::Util::max($f1, $f1 + $b1) <= List::Util::max($f2, $f2 + $b2));

}

# assert some things are strictly positive
sub assert_strictly_positive {

    for (my $i = 0; $i < @_; $i += 2) {

	croak "'$_[$i]' must be strictly positive"
	    if (!defined($_[$i+1]) || ($_[$i+1] <= 0));

    }

}

# assert some things are positive
sub assert_positive {

    for (my $i = 0; $i < @_; $i += 2) {

	croak "'$_[$i]' must be positive"
	    if (!defined($_[$i+1]) || ($_[$i+1] < 0));

    }

}

# assert some things are strictly less than other things
sub assert_strictly_less {
    
    for (my $i = 0; $i < @_; $i += 2) {
	for (my $j = $i + 2; $j < @_; $j += 2) {
	    
	    croak "'$_[$i]' must be strictly less than '$_[$j]'"
		if (!defined($_[$i+1]) || !defined($_[$j+1])
		    || ($_[$i+1] >= $_[$j+1]));
	    
	}
    }
    
}

# assert some things are less than other things
sub assert_less {
    
    for (my $i = 0; $i < @_; $i += 2) {
	for (my $j = $i + 2; $j < @_; $j += 2) {
	    
	    croak "'$_[$i]' must be less than '$_[$j]'"
		if (!defined($_[$i+1]) || !defined($_[$j+1])
		    || ($_[$i+1] > $_[$j+1]));
	    
	}
    }
    
}

# assert that some things are existing files
sub assert_file_exists {
    
    for (my $i = 0; $i < @_; $i += 2) {

	croak "'$_[$i]' must be an existing filename"
	    if (!defined($_[$i+1]) || !(-f $_[$i+1]));

    }

}

# assert that some things are non-existant files
sub assert_no_file_exists {

    for (my $i = 0; $i < @_; $i += 2) {

	croak "'$_[$i]' must be an non-existant filename"
	    if (!defined($_[$i+1]) || (-f $_[$i+1]));

    }

}

# make sure current directory contains files matching globs
sub assert_files_matching {

    foreach my $glob (@_) {

	croak "'@{[getcwd()]}' does not contain files matching '$glob'"
	    if !defined(glob $glob);

    }

}

# make sure current directory is empty of files matching globs
sub assert_no_files_matching {

    foreach my $glob (@_) {

	croak "'@{[getcwd()]}' is not empty of files matching '$glob'"
	    if defined(glob $glob);

    }

}

# check that directory exists and is accessible
sub check_directory {

    my ($dir) = @_;

    # try to create directory if it does not exist
    if (! -d $dir) {
	$dir = readlink($dir) if (-l $dir);
	system "mkdir -p '$dir' >/dev/null 2>&1"
    }

    # return if directory exists and is accessible
    return (-d $dir) && (-x $dir) && (-r $dir) && (-w $dir);

}

# assert that directory exists and is accessible
sub assert_directory {

    my ($dir) = @_;

    croak "'$dir' does not exist or is inaccessible" if !(check_directory $dir);

}

# parse SFT filename
sub parse_sft_filename {

    my ($path, $sft) = @_;

    # parse file name components
    my $name = (File::Spec->splitpath($path))[-1];
    #$name =~ m|^([A-Z])-(\d+)_(\1\d)_(\w+)-(\d{9})-(\d+)\.sft$| or
    $name =~ m|^([A-Z])-(\d+)_(\1\d)_(\w+)-(\w*)-*(\d{10})-(\d+)\.sft$|  or # fscan SFTs have different filename conventions... 
	croak "'$name' is not a valid SFT file name";

#    # check that SFT types are consistent
#    croak "'$name' is not an SFT of type '$sft->{type}'"
#	if (defined($sft->{type}) && $sft->{type} ne $4);

    # add info to hash
    $sft->{name} = $name;
    $sft->{num} = $2;
    $sft->{ifo} = $3;
    $sft->{type} = $4;
    $sft->{start} = $5;
    $sft->{span} = $6;

}

# read setup XML files
sub read_setup_xmls {

    my %toread = @_;

    my %setup;

    # read setup XML files
    foreach my $xmlfile ((SETUP_XML, SFT_STRETCH_XML, COMP_COST_XML)) {
	next if !(-f $xmlfile);

	# read XML file
	my $twig = XML::Twig->new();
	$twig->safe_parsefile($xmlfile) or
	    croak "XML::Twig->safe_parsefile failed: $@";
	
	# iterate over first-level elements
	foreach my $elt1 ($twig->root->children()) {
	    
	    # iterate over second-level elements
	    foreach my $elt2 ($elt1->children()) {
		
		# parse element into hash
		$setup{$elt1->name}->{$elt2->name} = $elt2->text;
		
	    }
	    
	}
	
    }
    
    # iterate over requested values
    foreach my $name (keys %toread) {

	# get keys
	my ($key1, $key2) = split /:/, $name;

	# croak if keys does not exist
	croak "Couldn't find '$name' in setup XML files"
	    if !defined($setup{$key1}->{$key2});

	# set referenced variable to value
	${$toread{$name}} = $setup{$key1}->{$key2};

    }

}

# write a setup XML file
sub write_setup_xml {

    my ($xmlfile, %towrite) = @_;

    my %xml;

    # iterate over requested values
    foreach my $name (keys %towrite) {

	# get keys
	my ($key1, $key2) = split /:/, $name;

	# create key and value in XML structure
	$xml{$key1}->{$key2} = $towrite{$name};

    }

    # write XML setup file
    my $xs = XML::Simple->new(
			      XMLDecl  => 1,
			      RootName => 'setup',
			      NoAttr   => 1
			      );
    open FILE, ">$xmlfile" or croak "Couldn't open '$xmlfile': $!";
    print FILE $xs->XMLout(\%xml);
    close FILE;

}

# write SFT stretch setup XML
sub write_sft_stretch_xml {
    write_setup_xml SFT_STRETCH_XML, @_;
}

# write computational cost XML
sub write_comp_cost_xml {
    write_setup_xml COMP_COST_XML, @_;
}

# read XML database
sub read_xml_db {

    my ($xmlfile, $rootname, $eltname, $keyname, $hash) = @_;

    # check if file exists
    croak "Couldn't find XML database file '$xmlfile'"
	if !(-f $xmlfile);

    # element parsing subroutine
    my $parse_elt = sub {

	my ($twig, $elt) = @_;

	# get element key
	my $key = $elt->first_child($keyname)->text;

	# get element contents
	$hash->{$key} = $elt->simplify();

	# cleanup
	$twig->purge;

    };

    # create XML parser
    my $twig = XML::Twig->new(twig_roots => {$eltname => $parse_elt});

    # read file
    my $fh;
    if ($xmlfile =~ /\.bz2$/) {
	$fh = new IO::Uncompress::Bunzip2 $xmlfile
	    or croak "Couldn't open '$xmlfile' with IO::Uncompress::Bunzip2: $!";
    }
    else {
	$fh = new IO::File $xmlfile
	    or croak "Couldn't open '$xmlfile' with IO::File: $!";
    }
    print "### (reading '$xmlfile' ...) ###\n";
    $twig->safe_parse($fh) or
	croak "XML::Twig->safe_parse failed: $@";
    $fh->close;

}

# write XML database
sub write_xml_db {

    my ($xmlfile, $rootname, $eltname, $sortfunc, $hash) = @_;

    # create XML parser
    my $xs = XML::Simple->new(
			      XMLDecl  => 1,
			      RootName => $rootname,
			      NoAttr   => 1,
			      );

    # create XML structure
    my %xml = ($eltname => [sort $sortfunc values %{$hash}]);

    # write file
    my $fh;
    if ($xmlfile =~ /\.bz2$/) {
	$fh = new IO::Compress::Bzip2 $xmlfile
	    or croak "Couldn't open '$xmlfile' with IO::Compress::Bzip2: $!";
    }
    else {
	$fh = new IO::File ">$xmlfile"
	    or croak "Couldn't open '$xmlfile' with IO::File: $!";
    }
    print "### (writing '$xmlfile' ...) ###\n";
    print $fh $xs->XMLout(\%xml);
    $fh->close;

}

# read SFT database
sub read_sft_db {

    my ($sfts) = @_;

    read_xml_db SFT_DB, 'sfts', 'sft', 'path', $sfts
	if (-f SFT_DB);

}

# write SFT database
sub write_sft_db {

    my ($sfts) = @_;

    write_xml_db SFT_DB, 'sfts', 'sft', sub {$a->{'path'} cmp $b->{'path'}}, $sfts;

}

# read template counts
sub read_density_db {

    my ($templates) = @_;

    read_xml_db DENSITY_DB, 'densities', 'point', 'freq', $templates;

}

# write template counts
sub write_density_db {

    my ($templates) = @_;

    write_xml_db DENSITY_DB, 'densities', 'point', sub {$a->{'freq'} <=> $b->{'freq'}}, $templates;

}

# read veto bands
sub read_veto_bands_db {

    my ($veto_bands) = @_;

    read_xml_db VETO_BANDS_DB, 'veto_bands', 'veto_band', 'freq', $veto_bands;

}

# write veto bands
sub write_veto_bands_db {

    my ($veto_bands) = @_;

    write_xml_db VETO_BANDS_DB, 'veto_bands', 'veto_band', sub {$a->{'freq'} <=> $b->{'freq'}}, $veto_bands;

}

# read search bands
sub read_search_bands_db {

    my ($search_bands) = @_;

    read_xml_db SRCH_BANDS_DB, 'search_bands', 'search_band', 'job', $search_bands;

}

# write search bands
sub write_search_bands_db {

    my ($search_bands) = @_;

    write_xml_db SRCH_BANDS_DB, 'search_bands', 'search_band', sub {$a->{'job'} <=> $b->{'job'}}, $search_bands;

}

# read upper_limit bands
sub read_ul_bands_db {

    my ($ul_bands) = @_;

    read_xml_db UL_BANDS_DB, 'upper_limit_bands', 'upper_limit_band', 'job', $ul_bands;

}

# write upper_limit bands
sub write_ul_bands_db {

    my ($ul_bands) = @_;

    write_xml_db UL_BANDS_DB, 'upper_limit_bands', 'upper_limit_band', sub {$a->{'job'} <=> $b->{'job'}}, $ul_bands;

}

# find the absolute path to named executable file
sub abs_exec_path {

    my ($name) = @_;

    my $path = $name;

    if (File::Spec->file_name_is_absolute($path)) {
	return $path if (-x $path);
	croak "'$name' is not an executable file";
    }

    foreach my $dir (EXEC_PATH) {
	$path = Cwd::abs_path(File::Spec->catfile($dir, $name));
	return $path if (-x $path);
    }

    croak "'$name' is not an executable file in the executable path";

}

# parse a file to find its identity strings
sub ident_strings {

    my ($file) = @_;

    # read in entire file
    my $contents;
    open FILE, "$file" or croak "Couldn't open '$file': $!";
    read FILE, $contents, -s FILE;
    close FILE;

    # search for identity strings
    my %ids;
    while ($contents =~ s|(\$[I][d][:][^\$]+\$)||) {
	@ids{$1} = 1;
    }

    return (sort keys %ids);

}

# build path and command line for run_exec* routines
sub path_cmd_run_exec {

    my ($name, $args) = @_;

    # find path of executable
    my $path = abs_exec_path $name;

    # build command path
    my $cmd = "$path";
    switch (ref $args) {
	case ('ARRAY') {
	    $cmd .= " '" . join("' '", @{$args}) . "'";
	}
	case ('HASH') {
	    foreach my $arg (sort keys %{$args}) {
		$cmd .= ' -';
		$cmd .= '-' if (length($arg) > 1);
		$cmd .= "$arg '$args->{$arg}'";
	    }
	}
	else {
	    croak "Invalid reference '$args'";
	}
    }

    # return path and command
    return ($path, $cmd);

}

# run an executable file with arguments
sub run_exec {

    # get path and command
    my ($path, $cmd) = path_cmd_run_exec @_;

    # execute command
    print '#' x 10, "\n";
    print "$path: @{[ident_strings $path]}\n";
    print "Executing $cmd\n";
    print '#' x 10, "\n";
    !system $cmd  or croak "'$path' failed";
    print '#' x 10, "\n";

}


# run an executable file with arguments and capture output
sub run_exec_output {

    # get path and command
    my ($path, $cmd) = path_cmd_run_exec @_;

    # execute command
    my @output;
    print '#' x 10, "\n";
    print "$path: @{[ident_strings $path]}\n";
    print "Executing $cmd\n";
    print '#' x 10, "\n";
    open PIPE, "$cmd |"  or croak "'$path' failed";
    while (my $line = <PIPE>) {
	chomp $line;
	push @output, $line;
    }
    print '#' x 10, "\n";

    # return output
    return @output;

}

# create a Condor submit file
sub condor_sub_file {

    my ($file, @args) = @_;

    # create file
    open FILE, ">$file" or croak "Couldn't open '$file': $!";

    # print standard lines
    print FILE "# global options set by @{[__PACKAGE__]}\n\n";
    print FILE "universe = vanilla\n";
    print FILE "initialdir = ", Cwd::abs_path(File::Spec->curdir()), "\n";
    print FILE "getenv = true\n";
    print FILE "notification = never\n";
    print FILE "log = condor.log\n";
    print FILE "\n";

    # print job-specific options
    print FILE "# this job's options and commands\n\n";
    while (@args) {
	my $name = shift @args;
	my $value = shift @args;

	# default deliminator and line ending
	my $delim = ' = ';
	my $endl = "\n";

	# check specific things for different options
	switch ($name) {
	    case ('executable') {

		# find path of the executable
		$value = abs_exec_path $value;

	    }
	    case ('queue') {

		# change delimator and line ending
		$delim = ' ';
		$endl = "\n\n";

	    }
	    #case ('account_group') {

	    #    # Add LDG account group to condor sub files 
	    #    print FILE "$value";

	    #}
	    #case ('account_user') {

	    #    # Add LDG account user to condor sub files 
	    #    print FILE "$value";

	    #}
	}

	# print option
	print FILE "$name$delim$value$endl";

    }

    # close file
    close FILE;

}

# validate local SFTs and return the path to local/global SFTs
sub get_check_local_sfts {

    my ($job) = @_;
    croak "Must supply a job number" if !defined($job);

    my $old_cwd = getcwd();

    my $sfts;
    print '-' x 10, "\n";
    
    # get paths to local and global SFTs
    my $local  = LOCAL_DIR('sfts');
    my $global = GLOBAL_DIR('sfts');
    assert_directory $global;

    # try to use local SFTs
    if (check_directory $local) {

	# master checksum file
	my $global_checksum = File::Spec->catfile($global, 'md5sums.txt');
	
	# local checksum files
	my $local_job_checksum = File::Spec->catfile($local, "md5sums.txt.$job");
	my $local_checksums    = File::Spec->catfile($local, "md5sums.txt.*");
	
	# for checking whether local checksum matches master checksum
	my $check = sub {
	    my ($local_checksum) = @_;
	    if (-r $local_checksum) {
		if (!system "diff --text --brief $local_checksum $global_checksum >/dev/null") {
		    print "SFT checksum $local_checksum matches $global_checksum\n";
		    $sfts = $local;
		    print "Using local SFTs: $sfts\n";
		    return 1;
		}
		else {
		    print "SFT checksum $local_checksum does not match $global_checksum\n";
		    return 0;
		}
	    }
	    else {
		print "SFT checksum $local_checksum does not exist\n";
		return 0;
	    }
	};
	
	# try all existing local checksum files
	foreach my $local_checksum (glob $local_checksums) {
	    last if &$check($local_checksum);
	}
	
	# if no valid checksums files were found
	if (!defined($sfts)) {
	    
	    # create a checksum file
	    print "Computing SFT checksum $local_job_checksum ...";
	    !system "rm -f $local_job_checksum"
		or croak "Couldn't remove '$local_job_checksum': $!";
	    chdir $local;
	    foreach my $sft (sort glob '*.sft') {
		!system "md5sum --binary '$sft' >> $local_job_checksum"
		    or croak "md5sum failed on '$sft': $!";
	    }
	    chdir $old_cwd;
	    print " done\n";
	    
	    # try this checksum file
	    &$check($local_job_checksum);
	    
	}

    }

    # only the global SFTs are available
    if (!defined($sfts)) {
	$sfts = $global;
	print "Using global SFTs: $sfts\n";
    }

    print '-' x 10, "\n";
    return $sfts;

}

# parse line from CFSv2 output file to hash
sub parse_CFSv2_output_line {

    my ($line) = @_;
    my @tokens = split /\s+/, $line;

    croak "'$line' is not 'freq alpha delta f1dot f2dot d3dot twoF log10BSGL twoFH1 twoFL1'" if @tokens != 10;

    my $template = {
        freq       => $tokens[0],
        alpha      => $tokens[1],
        delta      => $tokens[2],
        f1dot      => $tokens[3],
        f2dot      => $tokens[4],
        f3dot      => $tokens[5],
        twoF       => $tokens[6],
        log10BSGL  => $tokens[7],
        twoFH1     => $tokens[8],
        twoFL1     => $tokens[9],
    };
    #croak "'$line' is not 'freq alpha delta f1dot f2dot d3dot twoF twoFH1 twoFL1'" if @tokens != 9;

    #my $template = {
    #    freq       => $tokens[0],
    #    alpha      => $tokens[1],
    #    delta      => $tokens[2],
    #    f1dot      => $tokens[3],
    #    f2dot      => $tokens[4],
    #    f3dot      => $tokens[5],
    #    twoF       => $tokens[6],
    #    twoFH1     => $tokens[7],
    #    twoFL1     => $tokens[8],
    #};

    return $template;

}

# compute band covered by evolution of signal template in time
sub template_covering_band {

    my ($template, $T) = @_;

    # difference in frequency over data set due to spindown
    my $dfspin = ((($template->{f3dot} / 6  * $T) +
		   $template->{f2dot} / 2) * $T +
		  $template->{f1dot}    ) * $T;

    # extra frequency band due to sidereal Doppler motion
    # constant is (earth radius)*(sidereal angular frequency)/c
    # assume detector is at equator (cos latitude = 1)
    my $dfdoppl = 1.55e-6 * cos($template->{delta}) *
	List::Util::max($template->{freq}, $template->{freq} + $dfspin);

    # frequency band covered by template
    my $f0 = List::Util::min($template->{freq}, $template->{freq} + $dfspin) - $dfdoppl;
    my $f1 = List::Util::max($template->{freq}, $template->{freq} + $dfspin) + $dfdoppl;

    return ($f0, $f1 - $f0);

}
