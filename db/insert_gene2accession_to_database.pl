#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: insert_gene2accession_to_database.pl
#
#        USAGE: ./insert_gene2accession_to_database.pl  
#
#  DESCRIPTION: This script will insert the parsed information from the
#  				gene2accession file into the gene2accession_parsed file.
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Jason R. Dobson (JRD), dobson187@gmail.com
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 06/07/2012 06:47:25 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use DBI;

my $parsed_fh = "gene2accession_parsed";
my $dbh = DBI->connect("dbi:SQLite:dbname=dispatch.db","","",{ RaiseError => 1}) or die $DBI::errstr;
$dbh->do("DROP TABLE IF EXISTS gene2accession");
$dbh->do("CREATE TABLE gene2accession(mrna_accession BLOB, mrna_gi INT, dna_gi INT, dna_start INT, dna_stop INT, orientation TEXT, PRIMARY KEY ( mrna_gi, dna_gi))");
open my ($parsed_file), "<", $parsed_fh or die "Could not read from $parsed_fh $!\n";
while (<$parsed_file>) {
	my $line = $_;
	chomp ($line);
	my ($rna_accession, $rna_gi, $dna_gi, $dna_start, $dna_stop, $orientation) = split(/\t/, $line);
	$dbh->do("INSERT INTO gene2accession VALUES($rna_accession, $rna_gi, $dna_gi, $dna_start, $dna_stop, $orientation)");
}
