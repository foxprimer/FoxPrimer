package FoxPrimer::Model::Search::CreatedPrimers;
use Moose;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Model::Search::CreatedPrimers::cDNA;
use FoxPrimer::Model::Search::CreatedPrimers::ChIP;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::Search::CreatedPrimers - Catalyst Model

=head1 DESCRIPTION

This module searches the created primers databases for the user-defined
search string.

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

=head2 search_created_cdna_primers

This subroutine creates an instance of
FoxPrimer::Model::Search::CreatedPrimers::cDNA and runs the
'search_cdna_database' subroutine to return an Array Ref of primer pair
information Hash Refs.

=cut

sub search_created_cdna_primers {
    my $self = shift;

	# Create an instance of FoxPrimer::Model::Search::CreatedPrimers::cDNA
	# and run the 'search_cdna_database' subroutine to return an Array Ref
	# of primers matching the user's search string.
	my $cdna_search = FoxPrimer::Model::Search::CreatedPrimers::cDNA->new(
		search_string			=>	$self->search_string,
		accessions_to_search	=>	$self->accessions_to_search,
	);

	my $created_cdna_primers = $cdna_search->search_cdna_database;
	print Dumper $created_cdna_primers;

	return $created_cdna_primers;
}

__PACKAGE__->meta->make_immutable;

1;
