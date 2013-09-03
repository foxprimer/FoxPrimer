package FoxPrimer::Controller::SearchDatabase;
use Moose;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;

BEGIN {extends 'Catalyst::Controller'; }
__PACKAGE__->config(namespace => 'search');

=head1 NAME

FoxPrimer::Controller::SearchDatabase

=cut

=head1 AUTHOR

Jason R. Dobson, L<foxprimer@gmail.com>

=cut

=head1 DESCRIPTION

Catalyst Controller that controls the logic flow for searching the FoxPrimer
qPCR primer database.

=cut

=head2 base

Can place common logic to start chained dispatch here

=cut

sub base :Path :Args(0) {
    my ($self, $c) = @_;

    # Add the search_database template to the stash
    $c->stash(
        template    =>  'search_database.tt',
    );

    # Print a message to the debug log
    $c->log->debug('*** INSIDE BASE METHOD ***');

    # Load status messages
    $c->load_status_msgs;

    $c->forward('search_database');
}

=head2 search_database

This is the controller method for searching both the created and validated
primer databases

=cut

sub search_database :Private {
    my ($self, $c) = @_;

    # Test to make sure that a search string has been entered
    if ( $c->request->parameters->{search_string} ) {

        # Create an instance of FoxPrimer::Model::Search
        my $search = $c->model('Search')->new(
            search_string   =>  $c->request->parameters->{search_string},
        );

        # Run the 'search_databases' subroutine to search all of the
        # FoxPrimer databases for the user-defined search string. This
        # subroutine returns a Hash Ref of each primer type in Array Ref
        # format.
        my $primer_results = $search->search_databases;

        # Return the results to the user through the search_database.tt
        # template.
        $c->stash(
            template            => 'search_database.tt',

            created_primer_results      =>
                $primer_results->{created_cdna_primers},

            created_chip_primers        =>
                $primer_results->{created_chip_primers},

            validated_primer_results    =>
                $primer_results->{validated_cdna_primers},

            validated_chip_primers      =>
                $primer_results->{validated_chip_primers},
        );

    } else {

        # Return the user to the default page if no search terms
        # have been entered
        $c->stash(
            template    =>  'search_database.tt',
            status_msg  =>  
                "Please enter a search term in the search field to begin.",
        );
    }

#       # Pre-declare a hash-ref to hold any possible RefSeq
#       # accessions entered by the user in the search string
#       my $accessions_to_search = [];
#
#       # Use a regular expression to extract any possible RefSeq
#       # accessions and push these onto the accessions_to_search
#       # Array Ref
#       while ( $c->request->parameters->{search_string} =~
#           /(\w\w_\d+)/g ) {
#           push (@$accessions_to_search, $1);
#       }
#
#       # Pre-declare an empty Array Ref for each type of primer to
#       # return to the user
#       my $created_cdna_primers = [];
#       my $created_chip_primers = [];
#       my $validated_cdna_primers = [];
#       my $validated_chip_primers = [];
#
#       # Create an instance of each of the two cDNA database
#       # result sets
#       my $created_mrna_result_set =
#           $c->model('CreatedPrimers::Primer');
#       my $created_mrna_description_search_results =
#           $created_mrna_result_set->search(
#           {
#               description =>  
#               {
#                   'like', '%' .
#                   $c->request->parameters->{search_string}
#                   . '%',
#               },
#           }
#       );
#        # Placeholder for validated cDNA search
#        #
#        # END
#
#       # Iterate through the created cDNA search results adding
#       # each row to the Array Ref
#       while ( my $created_mrna_result =
#           $created_mrna_description_search_results->next ) {
#           push (@$created_cdna_primers,
#               $created_mrna_result
#           );
#       }
#
#       # If there are any RefSeq accessions identified, search the
#       # ChIP/Genomic databases and the mRNA databases
#       if ( @$accessions_to_search ) {
#
#           # Access the
#           # FoxPrimer::Model::Validated_Primer_Entry module
#           # and run the
#           # FoxPrimer::Model::Validated_Primer_Entry::chip_primer_search
#           # subroutine to see if any of the accessions
#           # searched have ChIP primers created or validated
#           # near them
#           my $chip_primers_found =
#               $c->model('Validated_Primer_Entry')->chip_primer_search(
#                   $c, $accessions_to_search
#           );
#
#           # Test to see if any created or validated primers
#           # have been found in the FoxPrimer database, if
#           # they have add the information to the
#           # created_chip_primers or validated_chip_primers
#           # Array Refs accordingly
#           if ( $chip_primers_found->{created_primers} ) {
#               push (@$created_chip_primers,
#                   @{$chip_primers_found->{created_primers}}
#               );
#           }
#           if ( $chip_primers_found->{validated_primers} ) {
#               push (@$validated_chip_primers,
#                   @{$chip_primers_found->{validated_primers}}
#               );
#           }
#           
#           # Access the
#           # FoxPrimer::Model::Validated_Primer_Entry module
#           # and run the
#           # FoxPrimer::Model::Validated_Primer_Entry::cdna_primer_search
#           # subroutine to see if any of the accessions
#           # searched have cDNA  primers created or validated
#           # near them
#           my $cdna_primers_found =
#               $c->model('Validated_Primer_Entry')->cdna_primer_search(
#                   $c,
#                   $accessions_to_search
#           );
#
#           # Test to see if any created or validated primers
#           # have been found in the FoxPrimer database, if
#           # they have add the information to the
#           # created_cdna_primers or validated_cdna_primers
#           # Array Refs accordingly
#           if ( $cdna_primers_found->{created_primers} ) {
#               push (@$created_cdna_primers,
#                   @{$cdna_primers_found->{created_primers}}
#               );
#           }
#           if ( $cdna_primers_found->{validated_primers} ) {
#               push (@$validated_cdna_primers,
#                   @{$cdna_primers_found->{validated_primers}}
#               );
#           }
#       }
#
#       # Return the results to the user through the
#       # search_database.tt template
#       $c->stash(
#           template            =>
#               'search_database.tt',
#
#           created_primer_results      =>  
#               $created_cdna_primers,
#
#           created_chip_primers        =>  
#               $created_chip_primers,
#
#           validated_primer_results    =>  
#               $validated_cdna_primers,
#
#           validated_chip_primers      =>  
#               $validated_chip_primers,
#       );
#
#   } else {
#
#       # Return the user to the default page if no search terms
#       # have been entered
#       $c->stash(
#           template    =>  'search_database.tt',
#           status_msg  =>  
#               "Please enter a search term in the search field to begin.",
#       );
#   }
}

__PACKAGE__->meta->make_immutable;

1;
