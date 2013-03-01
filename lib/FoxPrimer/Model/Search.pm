package FoxPrimer::Model::Search;
use Moose;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Schema;
use FoxPrimer::Model::Search::CreatedPrimers;
use FoxPrimer::Model::Search::ValidatedPrimers;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::Search - Catalyst Model

=head1 DESCRIPTION

This module is the sub-controller module, which takes the search string
entered by the user to search the FoxPrimer databases for primers related
to the search string.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 search_string

This Moose object contains the string with which to search the FoxPrimer
databases.

=cut

has search_string   =>  (
    is          =>  'ro',
    isa         =>  'Str'
);

=head2 gene2accession_schema

This Moose object is created by a lazy loader, which will create a
DBIx::Class::ResultSet object for the Gene2Accession database. This object
is private and can not be modified upon creation of a
FoxPrimer::Model::PrimerDesign object.

=cut

has _gene2accession_schema	=>	(
	is			=>	'ro',
	isa			=>	'FoxPrimer::Schema',
	default		=>	sub {
		my $self = shift;
		my $dsn = "dbi:SQLite:$FindBin::Bin/../db/gene2accession.db";
		my $schema = FoxPrimer::Schema->connect($dsn, '', '', '');
		return $schema;
	},
	required	=>	1,
	reader		=>	'gene2accession_schema',
);

=head2 search_databases

This subroutine takes the search string entered by the user and first
searches for parts of the search string resembling RefSeq mRNA accessions
and searches the accessions in the database for those matching the one
entered by the user. It also searches the description strings for each
primer pair for matches found in the search string.

=cut

sub search_databases {
    my $self = shift;

    # Run the 'find_full_accessions' subroutine to return an Array Ref of
    # full RefSeq mRNA accessions (if there were any to be found).
    my $full_accessions = $self->find_full_accessions;

    # Create an instance of FoxPrimer::Model::Search::CreatedPrimers to
    # search the FoxPrimer databases for created cDNA and ChIP primers.
}

=head2 find_full_accessions

This subroutine takes the Array Ref of possible RefSeq mRNAs from the
search string and searches the gene2accession database in order to find the
full RefSeq mRNA accession (if one exists) so that searching the primer
databases will be much faster.

=cut

sub find_full_accessions {
    my $self = shift;

    # Pre-declare an Array Ref to hold possible accessions
    my $accessions_to_search = [];

    # Copy the search string into a scalar string
    my $search_string = $self->search_string;

    # Use regular expressions to search for possible RefSeq mRNA accessions
    # and store the matches in the accessions_to_search Array Ref.
    while ( $search_string =~ /(\w\w_\d+)/g ) {
        push(@$accessions_to_search, $1);
    }

    # Pre-declare an Array Ref to hold the found full accessions
    my $full_accessions = [];

    # Test to make sure there are potential accessions to be searching for,
    # if there are none, return the empty Array Ref
    if (@$accessions_to_search) {

        # Create a result set for the Gene2accession database
        my $gene2accession_result_set =
        $self->gene2accession_schema->resultset('Gene2accession');

        # Iterate through the potential accessions and search the
        # gene2accession database for the full accession.
        foreach my $potential_accession (@$accessions_to_search) {
            my @search_results = $gene2accession_result_set->search(
                {
                    mrna_root   =>  $potential_accession,
                }
            );

            # If a result has been found, add the full mRNA accession to
            # the full_accessions Array Ref.
            foreach my $search_result (@search_results) {
                push(@$full_accessions, $search_result->mrna);
            }
        }

        return $full_accessions;
    } else {

        return $full_accessions;
    }
}

__PACKAGE__->meta->make_immutable;

1;
