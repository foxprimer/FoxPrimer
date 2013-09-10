package FoxPrimer::Controller::mRNA_Primer_Design;
use Moose;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;

BEGIN {extends 'Catalyst::Controller'; }
__PACKAGE__->config(namespace => 'mrna_primer_design');

=head1 NAME

FoxPrimer::Controller::mRNA_Primer_Design

=cut

=head1 AUTHOR

Jason R. Dobson, L<foxprimer@gmail.com>

=cut

=head1 DESCRIPTION

Catalyst Controller that controls the logic flow for the design of mRNA qPCR
primers.

=cut

=head2 base

Can place common logic to start chained dispatch here

=cut

sub base :Path :Args(0) {
    my ($self, $c) = @_;

    # Add the mrna_primer_design template to the stash
    $c->stash(
        template    =>  'mrna_primer_design.tt',
    );

    # Print a message to the debug log
    $c->log->debug('*** INSIDE BASE METHOD ***');

    # Load status messages
    $c->load_status_msgs;

    $c->forward('mrna_primer_design');
}

=head2 mrna_primer_design

This hidden method is the Controller logic that is used to design primers for
the amplification of cDNA/mRNA.

=cut

sub mrna_primer_design :Private {
    # Default paramets passed to a zero-argument part path
    my ($self, $c) = @_;

    if ( $c->request->method eq 'POST' ) {

        # Create an instance of FoxPrimer::Model::PrimerDesign 
        my $cdna_primer_design = $c->model('PrimerDesign')->new(
            species             =>  $c->request->parameters->{species},
            product_size_string =>  $c->request->parameters->{product_size},
            number_per_type     =>  $c->request->parameters->{number_per_type},
            intron_size         =>  $c->request->parameters->{intron_size},
            accessions_string   =>  $c->request->parameters->{genes},
        );

        my ($form_errors, $accession_errors, $accessions_to_make_primers) =
        $cdna_primer_design->validate_mrna_form;

        # If there are any form errors, return the errors to the user and end.
        if ( $form_errors && (scalar(@{$form_errors}) >= 1) ) {
            $c->stash(
                error_msg   =>  $form_errors,
                template    =>  'mrna_primer_design.tt',
            );
        } else {

            # If there were no valid RefSeq mRNA accessions entered, return an
            # error message to the user.
            if ( ! @{$accessions_to_make_primers} ) {
                $c->stash(
                    error_msg   =>  $accession_errors,
                    template    =>  'mrna_primer_design.tt'
                );
            } else {

                # Create an instance of
                # FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign
                my $primer_design =
                $c->model('PrimerDesign::cdnaPrimerDesign')->new(
                    species             =>  $c->request->parameters->{species},

                    product_size_string =>
                    $c->request->parameters->{product_size},

                    number_per_type     =>
                    $c->request->parameters->{number_per_type},

                    intron_size         =>
                    $c->request->parameters->{intron_size},
                        
                    primers_to_make     =>  $accessions_to_make_primers
                );

                # Run the 'create_primers' subroutine to return an insert
                # statement of primers to be inserted into the FoxPrimer created
                # primers database and returned to the user.
                my ($created_cdna_primers, $primer3_error_messages) =
                $primer_design->create_primers;

                if ( $primer3_error_messages && ( scalar ( @{$primer3_error_messages}) >= 1 ) ) {
                    push(@{$accession_errors}, @{$primer3_error_messages});
                }

                # If there are any primers to return to the user, insert them
                # into the FoxPrimer created primers database, and return them
                # to the user.
                if ($created_cdna_primers && ( scalar( @{$created_cdna_primers}) >= 1 )) {
                    # Create a FoxPrimer::Model::CreatedPrimers::Primer result
                    # set to insert the primers into the FoxPrimer database.
                    my $created_primers_result_set =
                        $c->model('CreatedPrimers::CdnaPrimer');

                    # Insert the primers into the created primers database.
                    $created_primers_result_set->populate(
                        $created_cdna_primers
                    );

                    $c->stash(
                        status_msg      =>  'Primers have been designed',
                        error_msg       =>  $accession_errors,
                        template        =>  'mrna_primer_design.tt',
                        primer_results  =>  $created_cdna_primers
                    );
                }
            }
        }
    } else {
        $c->stash(
            template        =>  'mrna_primer_design.tt',
            status_msg      =>  'Please enter primer information',
        );
    }
}

__PACKAGE__->meta->make_immutable;

1;
