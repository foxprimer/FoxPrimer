#!/usr/bin/env perl 

use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Schema;

# Download the gene2accession file from the NCBI FTP site. Please note this address may change,
# and in which case this script will no longer be valid.
`wget ftp://ftp.ncbi.nlm.nih.gov/gene/DATA//gene2accession.gz`;
`mv gene2accession.gz db/gene2accession.gz`;
`gunzip db/gene2accession.gz`;
# Pre-define an Array Ref to hold the insertion data for the gene2accession database
my $insert_statement = [];

# Pre-declare a Hash Ref to hold the current insert statement
my $current_insert = {
	mrna		=>	'',
	mrna_root	=>	'',
	mrna_gi		=>	'',
	dna_gi		=>	'',
	dna_start	=>	'',
	dna_stop	=>	'',
	orientation	=>	'',
};


# Open the gene2accession file
open my $gene2accession_file, "<", "db/gene2accession" or die "Could not read from db/gene2accession $!\n";
# Read the gene2accession file
while (<$gene2accession_file>) {
	my $line = $_;
	chomp ($line);
	unless ($line =~ /^#/) {
		my ($tax_id, $GeneID, $status, $RNA_nucleotide_accession,
			$RNA_nucleotide_gi, $protein_accession,  $protein_gi,
			$genomic_nucleotide_accession, $genomic_nucleotide_gi,
			$start_position_on_the_genomic_accession,
			$end_position_on_the_genomic_accession, $orientation,
			$assembly) = split(/\t/, $line);
		if ( ($RNA_nucleotide_accession =~ /\w\w_\d+/) && 
			($RNA_nucleotide_gi =~ /^\d+$/) && 
			($genomic_nucleotide_gi =~ /^\d+$/) &&
			($start_position_on_the_genomic_accession =~ /^\d+/) && 
			($end_position_on_the_genomic_accession =~ /^\d+$/) && 
			$genomic_nucleotide_accession =~ /^NC_/) {
			# Declare a string for the mRNA root
			my $mrna_root = '';
			if ( $RNA_nucleotide_accession =~ /^(\w\w_\d+)\.\d+$/ ) {
				$mrna_root = $1;
			} else {
				$mrna_root = $RNA_nucleotide_accession;
			}
			# See if the mRNA has already been found
			if ( $RNA_nucleotide_accession eq $current_insert->{mrna} ) {
				
				# If the current line is not mapped to the 'Alternate'
				# assembly, replace the current_insert with the variables
				# from the current line.
				if ( $assembly !~ /Alternate/ ) {
					$current_insert = {
						mrna		=>	$RNA_nucleotide_accession,
						mrna_root	=>	$mrna_root,
						mrna_gi		=>	$RNA_nucleotide_gi,
						dna_gi		=>	$genomic_nucleotide_gi,
						dna_start	=>
							$start_position_on_the_genomic_accession,
							
						dna_stop	=>
							$end_position_on_the_genomic_accession,

						orientation	=>	$orientation,
					};
				}
			} else {
				if ( $current_insert->{mrna} ) {
					push(@$insert_statement, $current_insert);
					$current_insert = {
						mrna		=>	$RNA_nucleotide_accession,
						mrna_root	=>	$mrna_root,
						mrna_gi		=>	$RNA_nucleotide_gi,
						dna_gi		=>	$genomic_nucleotide_gi,
						dna_start	=>
							$start_position_on_the_genomic_accession,
							
						dna_stop	=>
							$end_position_on_the_genomic_accession,

						orientation	=>	$orientation,
					};
				} else {
					$current_insert = {
						mrna		=>	$RNA_nucleotide_accession,
						mrna_root	=>	$mrna_root,
						mrna_gi		=>	$RNA_nucleotide_gi,
						dna_gi		=>	$genomic_nucleotide_gi,
						dna_start	=>
							$start_position_on_the_genomic_accession,
							
						dna_stop	=>
							$end_position_on_the_genomic_accession,

						orientation	=>	$orientation,
					};
				}
			}
		}
	}
}
close $gene2accession_file;
push(@$insert_statement, $current_insert);
if ( $insert_statement->[-1]{mrna} eq $insert_statement->[-2]{mrna} ) {
	pop(@$insert_statement);
}
unlink("$FindBin::Bin/../db/gene2accession");
unlink("$FindBin::Bin/../db/gene2accession.db");
my $delete_statement = "sqlite3 $FindBin::Bin/../db/gene2accession.db < " .
"$FindBin::Bin/../db/gene2accession.sql";
`$delete_statement`;
my $dbi_string = 'dbi:SQLite:' . "$FindBin::Bin/../db/gene2accession.db";
my $schema = FoxPrimer::Schema->connect($dbi_string);
my $result_class = $schema->resultset('Gene2accession');
$result_class->populate($insert_statement);
