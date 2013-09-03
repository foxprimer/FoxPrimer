package FoxPrimer::Model::Search::CreatedPrimers;
use Moose::Role;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;
use FoxPrimer::Model::Search::CreatedPrimers::ChIP;

with 'FoxPrimer::Model::Search::CreatedPrimers::cDNA';

=head1 NAME

FoxPrimer::Model::Search::CreatedPrimers - Catalyst Model

=head1 DESCRIPTION

This module searches the created primers databases for the user-defined search
string.

=head1 AUTHOR

Jason R Dobson, L<foxprimer@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

=head2 search_created_cdna_primers

This subroutine creates an instance of
FoxPrimer::Model::Search::CreatedPrimers::cDNA and runs the
'search_cdna_database' subroutine to return an Array Ref of primer pair
information Hash Refs.

=cut

sub search_created_cdna_primers {
    my $self = shift;
    my $search_string = shift;
    my $accessions_to_search = shift;

    # Run the 'search_cdna_database' subroutine to return an Array Ref of
    # primers matching the user's search string.
    my $created_cdna_primers = $self->search_cdna_database(
        $search_string,
        $accessions_to_search,
    );

    return $created_cdna_primers;
}

1;
