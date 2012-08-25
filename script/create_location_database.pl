#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: create_location_database.pl
#
#        USAGE: ./create_location_database.pl  
#
#  DESCRIPTION: This is a helper script designed to insert concatenated accesion
#  				and location strings into the relative location table.
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Jason R. Dobson (JRD), dobson187@gmail.com
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 08/17/2012 05:06:42 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use lib './lib/';
use FoxPrimer::Schema;
use Data::Dumper;

# Connect to the database and create a result set
my $chip_schema = FoxPrimer::Schema->connect("dbi:SQLite:db/chip_primers.db");
my $location_result_set = $chip_schema->resultset('RelativeLocation');
# Declare a list of potential locations
my $locations = [
"_2.5K_Downstream",
"_3Prime_UTR",
"_5K_Downstream",
"_5K_Upstream",
"_5Prime_UTR",
"_10K_Downstream",
"_10K_Upstream",
"_25K_Downstream",
"_25K_Upstream",
"_50K_Downstream",
"_50K_Upstream",
"_100K_Downstream",
"_100K_Upstream",
"_Exons",
"_Introns",
"_Promoters",
];
# Declare the locations of the promoter files for each species
my $promoter_files = {
	Human			=>	'root/static/files/Human_Index/Human_Promoters.bed',
	Mouse			=>	'root/static/files/Mouse_Index/Mouse_Promoters.bed',
	DMelanogaster	=>	'root/static/files/DMelanogaster_Index/DMelanogaster_Promoters.bed',
};
# Create a Array Ref to hold the populate calls
my $populate_array = [];
# Create a Hash Ref to ensure all entered names are unique
my $unique_names = {};
# Iterate through the species, opening the promoter file of each.
# In each promoter file, extract the RNA accessions and append the acccession
# and species to each of the locations.
# Finally, each appended string will be inserted into the database.
foreach my $species ( "Human", "Mouse", "DMelanogaster" ) {
	my $promoter_fh = $promoter_files->{$species};
	open my $promoter_file, "<", $promoter_fh or die "Could not read from $promoter_fh $!\n";
	while (<$promoter_file>) {
		my $line = $_;
		chomp $line;
		my ($chr, $start, $stop, $accession_string, $rest_of_line) = split(/\t/, $line);
		my $accession;
		if ( $accession_string =~ /^(\w\w_\d+?)_up/ ) {
			$accession = $1;
		}
		die "Could not match the accession from $accession_string" unless $accession;
		foreach my $location ( @$locations ) {
			my $location_string = $accession . '-' . $species . $location;
			unless ( $unique_names->{$location_string} ) {
				push (@$populate_array, { location	=>	$location_string });
				$unique_names->{$location_string} = 1;
			}
		}
	}
}
$location_result_set->populate($populate_array);
