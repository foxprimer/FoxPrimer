package FoxPrimer::Controller::Add_Motif;
use Moose;
use namespace::autoclean;
use File::Temp;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;

BEGIN {extends 'Catalyst::Controller'; }
with 'FoxPrimer::Model::AvailableMotifs';
__PACKAGE__->config(namespace => 'add_motif');

=head1 NAME

FoxPrimer::Controller::Add_Motif

=cut

=head1 AUTHOR

Jason R. Dobson, L<foxprimer@gmail.com>

=cut

=head1 DESCRIPTION

Catalyst Controller that controls the logic flow for user-addition of new motifs
to the ChIP qPCR primer design functions.

=cut

=head2 base

Can place common logic to start chained dispatch here.

=cut

sub base :Path :Args(0) {
    my ($self, $c) = @_;

    # Add the mrna_primer_design template to the stash
    $c->stash(
        template    =>  'add_motif.tt',
        status_msg  =>  'Please enter information about a motif to upload',
    );

    # Print a message to the debug log
    $c->log->debug('*** INSIDE BASE METHOD ***');

    # Load status messages
    $c->load_status_msgs;

    $c->forward('add_motif');
}

=head2 add_motif

=cut

sub add_motif :Private   {
    my ($self, $c)  = @_;

    if ( $c->request->method eq 'POST' ) {

        # Check to see that the form has been submitted.
        if ( $c->request->parameters->{motif_submit} eq 'yes' ) {

            # Check to make sure that a peaks file has been uploaded
            if ( my $upload = $c->request->upload('motif_file') ) {

                # Copy the motif file into a local scalar
                my $motif_file = $upload->filename;

                # Create a File::Temp object to store the MEME file
                my $temp_motif_file = File::Temp->new();

                # Ensure that the file is copied to the temporary location
                unless ( $upload->link_to($temp_motif_file) ||
                    $upload->copy_to($temp_motif_file) ) {
                    $c->stash(
                        template    =>  'add_motif.tt',
                            
                        error_msg   =>  
                        ["Failed to copy '$motif_file' to  '$temp_motif_file': $!"],
                    );
                }

                # Remove whitespace from name
                my $motif_name = $c->request->parameters->{motif_name};
                chomp($motif_name);
                $motif_name =~ s/\s/-/g;

                # Check to see if the motif is already installed
                if ( $self->motif_index->{$motif_name} ) {
                    $c->stash(
                        template    =>  'add_motif.tt',
                        error_msg   =>  
                        "The motif name $motif_name is already in use.",
                    );
                } else {

                    # Create an instance of FoxPrimer::Model::AddMotif
                    my $add_motif = $c->model('AddMotif')->new(
                        motif_name  =>  $motif_name,
                        motif_file  =>  $temp_motif_file,
                    );

                    # Run the add_motif subroutine, which returns a Boolean
                    # value. If this value is true then the file was a valid
                    # MEME-format motif, otherwise it was not.
                    if ( $add_motif->add_motif ) {
                        $c->stash(
                            template    =>  'add_motif.tt',
                            status_msg  =>  
                            'The motif ' . $motif_name . ' was added to the ' .
                            'list of available motifs.',
                        );
                    } else {
                        $c->stash(
                            template    =>  'add_motif.tt',
                            error_msg   =>  
                            'The file uploaded is not a valid file for motif ' .
                            'searching',
                        );
                    }
                }
            } else {
                $c->stash(
                    template    =>  'add_motif.tt',
                    status_msg  =>  'You must upload a MEME-format motif file',
                );
            }
        } else {
            $c->stash(
                template    =>  'add_motif.tt',
                status_msg  =>  'You must upload a MEME-format motif file',
            );
        }
    } else {
        $c->stash(
            template    =>  'add_motif.tt',
            status_msg  =>  'Please enter information about a motif to upload',
        );
    }

}

1;
