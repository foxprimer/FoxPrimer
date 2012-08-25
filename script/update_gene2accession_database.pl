#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: update_gene2accession_database.pl
#
#        USAGE: ./update_gene2accession_database.pl  
#
#  DESCRIPTION: Run this script to update the gene2accession database
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: Do not run this script if you have low memory or CPU, such
#        		as on the free tier (micro) instance on Amazon EC2.
#       AUTHOR: Jason R. Dobson (JRD), dobson187@gmail.com
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 08/25/2012 12:28:11 AM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use lib 'lib';
use FoxPrimer::Schema;

# Download the gene2accession file from the NCBI FTP site. Please note this address may change,
# and in which case this script will no longer be valid.
`wget ftp://ftp.ncbi.nlm.nih.gov/gene/DATA//gene2accession.gz`;
`mv gene2accession.gz db/gene2accession.gz`;
`gunzip db/gene2accession.gz`;
# Pre-define an Array Ref to hold the insertion data for the gene2accession database
my $insert_statement = [];
# Open the gene2accession file
open my $gene2accession_file, "<", "db/gene2accession" or die "Could not read from db/gene2accession $!\n";
# Read the gene2accession file
while (<$gene2accession_file>) {
	my $line = $_;
	chomp ($line);
	unless ($line =~ /^#/) {
		my ($tax_id, $GeneID, $status, $RNA_nucleotide_accession,  $RNA_nucleotide_gi, $protein_accession,  $protein_gi, 
			$genomic_nucleotide_accession, $genomic_nucleotide_gi, $start_position_on_the_genomic_accession, 
			$end_position_on_the_genomic_accession, $orientation, $assembly) = split(/\t/, $line);
		if ( ($RNA_nucleotide_accession =~ /\w\w_\d+/) && ($RNA_nucleotide_gi =~ /^\d+$/) && ($genomic_nucleotide_gi =~ /^\d+$/) &&
			($start_position_on_the_genomic_accession =~ /^\d+/) && ($end_position_on_the_genomic_accession =~ /^\d+$/) && $orientation ) {
			# Declare a string for the mRNA root
			my $mrna_root = '';
			if ( $RNA_nucleotide_accession =~ /^(\w\w_\d+)\.\d+$/ ) {
				$mrna_root = $1;
			} else {
				$mrna_root = $RNA_nucleotide_accession;
			}
			push(@$insert_statement, {
					mrna		=>	$RNA_nucleotide_accession,
					mrna_root	=>	$mrna_root,
					mrna_gi		=>	$RNA_nucleotide_gi,
					dna_gi		=>	$genomic_nucleotide_gi,
					dna_start	=>	$start_position_on_the_genomic_accession,
					dna_stop	=>	$end_position_on_the_genomic_accession,
					orientation	=>	$orientation,
				}
			);
		}
	}
}
`rm db/gene2accession`;
my $schema = FoxPrimer::Schema->connect('dbi:SQLite:db/gene2accession.db');
my $result_class = $schema->resultset('Gene2accession');
`sqlite3 db/gene2accession.db "delete from Gene2accession"`;
$result_class->populate($insert_statement);
