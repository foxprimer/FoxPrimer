package FoxPrimer::Model::Search::CreatedPrimers::cDNA;
use Moose;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Schema;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::Search::CreatedPrimers::cDNA - Catalyst Model

=head1 DESCRIPTION

This module searches the created cDNA primers database and returns entries
similar to the search string defined by the user.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 accessions_to_search

This Moose object holds an Array Ref of accessions to search for in the
created primers databases.

=cut

has accessions_to_search    =>  (
    is          =>  'ro',
    isa         =>  'ArrayRef',
);

=head2 search_string

This Moose object holds the search string the user has entered, which will
be used to search the description field.

=cut

has search_string   =>  (
    is          =>  'ro',
    isa         =>  'Str'
);

=head2 _cdna_primers_schema

This Moose object contains the FoxPrimer::Schema object used to connect to
the cDNA primers database.

=cut

has _cdna_primers_schema	=>	(
	is			=>	'ro',
	isa			=>	'FoxPrimer::Schema',
	default		=>	sub {
		my $self = shift;
		my $dsn = "dbi:SQLite:$FindBin::Bin/../db/primers.db";
		my $schema = FoxPrimer::Schema->connect($dsn, '', '', '');
		return $schema;
	},
	required	=>	1,
	reader		=>	'cdna_primers_schema',
);

=head2 search_cdna_database

This is the main subroutine which searches both the description string and
the RefSeq mRNA accession string. This subroutine returns an Array Ref of
Hash Refs of primer information.

=cut

sub search_cdna_database {
	my $self = shift;

	# Pre-declare an Array Ref to hold the Hash Refs of primers to return
	# to the user.
	my $primers_found = [];

	# Run the 'search_mrna_accessions' subroutine to return any cDNA
	# primers that match the potential accessions found.
	my $accession_matches = $self->search_mrna_accessions;

	# If there were any mRNA accession matches, add the primers to the
	# primers_found Array Ref.
	if (@$accession_matches) {
		push(@$primers_found, @$accession_matches);
	}

	# Run the 'search_descriptions' subroutine to return and cDNA primers
	# whose mRNA descriptions are similar to the user-defined search
	# string.
	my $description_matches = $self->search_descriptions;

	# If there were any description matches, add the primers to the
	# primers_found Array Ref.
	if (@$description_matches) {
		push(@$primers_found, @$description_matches);
	}

	# If there were primers found by either search, run the 'return_unique'
	# subroutine to be sure to only return unique primers to the user.
	if (@$primers_found) {
		return $self->return_unique($primers_found);
	} else {

		# Return the empty Array Ref
		return $primers_found;
	}
}

=head2 search_mrna_accessions

This subroutine searches the created cDNA primers database for matches by
the mRNA field.

=cut

sub search_mrna_accessions {
	my $self = shift;

	# Pre-declare an Array Ref for primers found.
	my $mrna_matches = [];

	# Create a primer results set
	my $cdna_primers_resultset =
	$self->cdna_primers_schema->resultset('Primer');

	# Search the result set for the accessions_to_search in the accession
	# field.
	my @search_results = $cdna_primers_resultset->search(
		{
			accession	=>	[@{$self->accessions_to_search}],
		}
	);

	# Add the search results to mrna_matches Array Ref if there are any
	# results.
	if (@search_results) {
		push(@$mrna_matches, @search_results);
	}

	return $mrna_matches;
}

=head2 search_descriptions

This subroutine takes the entire search string defined by the user and
searches the description field of the created cDNA primers database to find
potential matches.

=cut

sub search_descriptions {
	my $self = shift;

	# Pre-declare an Array Ref to hold search matches.
	my $description_matches = [];

	# Copy the search string into a local array split by spaces
	my @search_items = split(/\s/, $self->search_string);

	# Create a primer results set
	my $cdna_primers_resultset =
	$self->cdna_primers_schema->resultset('Primer');

	# Iterate through the search terms and search the description field
	foreach my $search_string (@search_items) {

		# Add % characters around the search term for SQL searching.
		$search_string = '%' . $search_string . '%';

		# Search the created cDNA primers database in the descriptions field
		# for similar terms to the search string
		my $description_search_results = $cdna_primers_resultset->search(
			{
				description	=>	{ like	=>	$search_string }
			}
		);

		# If there are any results returned, add them to the
		# description_matches Array Ref.
		while ( my $description_search_result =
			$description_search_results->next) {
			push(@$description_matches, $description_search_result);
		}
	}

	return $description_matches;
}

=head2 return_unique

This subroutine iterates through the found primer pairs and removes
duplicates so that only unique primer pairs are returned to the user.

=cut

sub return_unique {
	my ($self, $all_primers) = @_;

	# Pre-declare an Array Ref to hold the unique primer pairs
	my $unique_primer_pairs = [];

	# Pre-declare a Hash Ref to define which primer pairs have already been
	# stored in the unique_primer_pairs Array Ref to be returned to the
	# user.
	my $seen_primers = {};

	# Iterate through the all_primers Array Ref, determining which primers
	# are unique by using the seen_primers Hash Ref. If a primer is unique,
	# add it to the unique_primer_pairs Array Ref.
	foreach my $primer_pair (@$all_primers) {
		
		# Create a string for this unique primer.
		my $unique_string = join(".", $primer_pair->left_primer_sequence,
			$primer_pair->right_primer_sequence, $primer_pair->accession
		);

		# Test if this primer pair has already been 'seen'.
		unless ( $seen_primers->{$unique_string} ) {
			push(@$unique_primer_pairs, $primer_pair);
			$seen_primers->{$unique_string} = 1;
		}
	}

	return $unique_primer_pairs;
}

__PACKAGE__->meta->make_immutable;

1;
