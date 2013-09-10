package FoxPrimer::Controller::ChIP_Primer_Design;
use Moose;
use namespace::autoclean;
use File::Temp;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;

BEGIN {extends 'Catalyst::Controller'; }
with 'FoxPrimer::Model::PrimerDesign::chipPrimerDesign::AvailableGenomes';
with 'FoxPrimer::Model::AvailableMotifs';
with 'FoxPrimer::Model::PrimerDesign::MisprimingLibrary';
__PACKAGE__->config(namespace => 'chip_primer_design');

=head1 NAME

FoxPrimer::Controller::ChIP_Primer_Design

=cut

=head1 AUTHOR

Jason R. Dobson, L<foxprimer@gmail.com>

=cut

=head1 DESCRIPTION

Catalyst Controller that controls the logic flow for the design of ChIP qPCR
primers.

=cut

=head2 base

Can place common logic to start chained dispatch here

=cut

sub base :Path :Args(0) {
    my ($self, $c) = @_;

    # Add the chip_primer_design template to the stash
    $c->stash(
        template    =>  'chip_primer_design.tt',
        status_msg  =>  'Please enter primer information',
        genomes     =>  $self->ucsc_genomes,
        motifs      =>  $self->motif_index,
        mispriming  =>  $self->mispriming_files,
    );

    # Print a message to the debug log
    $c->log->debug('*** INSIDE BASE METHOD ***');

    # Load status messages
    $c->load_status_msgs;

    $c->forward('chip_primer_design');
}

=head2 chip_primer_design

This subroutine controls the logic for designing ChIP-qPCR primers.

=cut

sub chip_primer_design :Private  {
    my ($self, $c) = @_;

    if ( $c->request->method eq 'POST' ) {
        # Check to see that the form has been submitted.
        if ( $c->request->parameters->{peaks_submit} eq 'yes' ) {
            # Check to make sure that a peaks file has been uploaded
            if ( my $upload = $c->request->upload('peaks') ) {

                # Copy the file handle for the peaks file into
                # $peaks_file
                my $peaks_file = $upload->filename;

                # Create a File::Temp object to store the file of peaks
                my $temp_peaks_file = File::Temp->new();

                # Ensure that the file is copied to the temporary location
                unless ( $upload->link_to($temp_peaks_file) ||
                    $upload->copy_to($temp_peaks_file) ) {
                    $c->stash(
                        template    =>  
                            'chip_primer_design.tt',
                            
                        error_msg   =>  
                        ["Failed to copy '$peaks_file' to  '$temp_peaks_file': $!"],
                        
                        genomes     =>  $self->ucsc_genomes,
                        mispriming  =>  $self->mispriming_files,
                        motifs      =>  $self->motif_index,
                    );
                }

                # Create an instance of FoxPrimer::Model::PrimerDesign and run
                # the 'validate_chip_form subroutine to determine if the form
                # has been filled out correctly by the user.
                my $primer_design = $c->model('PrimerDesign')->new(
                    genome                  =>
                    $c->request->parameters->{genome},

                    product_size_string     =>
                    $c->request->parameters->{product_size},

                    motif                   =>
                    $c->request->parameters->{known_motif},
                );
                my $form_errors = $primer_design->validate_chip_form;

                # If there are any errors in the form, cease ChIP primer design
                # and return the errors to the user.
                if ( $form_errors && (scalar(@{$form_errors} >= 1))) {
                    $c->stash(
                        template    =>  'chip_primer_design.tt',
                            
                        error_msg   =>  $form_errors,
                        
                        genomes     =>  $self->ucsc_genomes,
                        motifs      =>  $self->motif_index,
                        mispriming  =>  $self->mispriming_files,
                    );

                } else {

                    # Create an instance of
                    # FoxPrimer::Model::PrimerDesign::chipPrimerDesign
                    my $chip_primer_design  =
                    $c->model('PrimerDesign::chipPrimerDesign')->new(
                        product_size    =>
                        $c->request->parameters->{product_size},
                        motif           =>
                        $c->request->parameters->{known_motif},
                        genome          =>  $c->request->parameters->{genome},
                        bed_file        =>  $temp_peaks_file,
                        mispriming_file =>
                        $self->mispriming_files->{$c->request->parameters->{mispriming}},
                    );

                    # Check to see if there were any errors in the BED file
                    # uploaded by the user.
                    if ( $chip_primer_design->bed_file_errors &&
                        (scalar(@{$chip_primer_design->bed_file_errors}) >=1 ) )
                    {

                        # Return the messages to the user
                        $c->stash(
                            template    =>  'chip_primer_design.tt',
                                
                            error_msg   =>  $chip_primer_design->bed_file_errors,
                            
                            genomes     =>  $self->ucsc_genomes,
                            motifs      =>  $self->motif_index,
                            mispriming  =>  $self->mispriming_files,
                        );
                    } else {

                        # Design the primers
                        my ($designed_primers, $design_errors) =
                        $chip_primer_design->design_primers;

                        # If primers were designed, add them to the database
                        if ( $designed_primers && scalar ( @{$designed_primers} ) >= 1 ) {

                            # Create a
                            # FoxPrimer::Model::CreatedPrimers::ChipPrimer
                            # result set to insert the primers into the
                            # FoxPrimer created primers database
                            my $created_primers_result_set =
                            $c->model('CreatedPrimers::ChipPrimer');

                            # Insert the primers into the created primers database.
                            $created_primers_result_set->populate(
                                $designed_primers
                            );
                        }

                        # Return the primers or errors to the user
                        $c->stash(
                            template    =>  'chip_primer_design.tt',
                                
                            error_msg   =>  $design_errors,
                            
                            genomes     =>  $self->ucsc_genomes,
                            motifs      =>  $self->motif_index,
                            mispriming  =>  $self->mispriming_files,
                            primers     =>  $designed_primers,
                        );
                    }
                } 
            } else {
                $c->stash(
                    template    =>  'chip_primer_design.tt',
                    status_msg  =>  'You must upload a file of BED coordinates for primer design',
                    genomes     =>  $self->ucsc_genomes,
                    motifs      =>  $self->motif_index,
                    mispriming  =>  $self->mispriming_files,
                );
            }
        } else {
            $c->stash(
                template    =>  'chip_primer_design.tt',
                status_msg  =>  'You must upload a file of BED coordinates for primer design',
                genomes     =>  $self->ucsc_genomes,
                motifs      =>  $self->motif_index,
                mispriming  =>  $self->mispriming_files,
            );
        }
    } else {
        $c->stash(
            template    =>  'chip_primer_design.tt',
            status_msg  =>  'Please enter primer information',
            genomes     =>  $self->ucsc_genomes,
            mispriming  =>  $self->mispriming_files,
        );
    }
}

__PACKAGE__->meta->make_immutable;

1;
