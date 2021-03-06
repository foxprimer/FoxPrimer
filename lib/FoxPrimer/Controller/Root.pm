package FoxPrimer::Controller::Root;
use Moose;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in FoxPrimer.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

FoxPrimer::Controller::Root - Root Controller for FoxPrimer

=head1 DESCRIPTION

This is the controller root for the FoxPrimer application. It handles
the data-verification and transfer of information between the View 
and the Model.

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Load the default page for FoxPrimer. This page will display the
    # default page for the application, with brief descriptions of
    # methods and usage for the application.
    $c->stash(
        template    =>  'home.tt',
        status_msg  =>  
            'Welcome to the FoxPrimer qPCR Primer Design Suite!',
    );
}

=head2 chip_primer_design_shell

This subroutine is used to create the default ChIP primer design form.

=cut

#sub chip_primer_design_shell :Local {
#    my ($self, $c) = @_;
#    $c->stash(
#        template    =>  'chip_primer_design.tt',
#        status_msg  =>  
#            'Please fill out the form below to begin making primers',
#
#        motifs      =>
#            $c->model('AvailableMotifs')->available_motifs,
#
#        genomes     =>
#            $c->model('PrimerDesign::chipPrimerDesign::AvailableGenomes')->installed_genomes,
#    );
#}


=head2 chip_primer_design

This is the hidden subroutine to design ChIP primers for the user. It uses
a file of BED coordinates uploaded by the user to design primers for qPCR.
Primers can be designed to flank either a motif or a peak summit.

=cut

#sub chip_primer_design :Chained('/') :PathPart('chip_primer_design') :Args(0) {
#    my ($self, $c) = @_;
#
#    # Check to see that the form has been submitted.
#    if ( $c->request->parameters->{peaks_submit} eq 'yes' ) {
#
#        # Check to make sure that a peaks file has been uploaded
#        if ( my $upload = $c->request->upload('peaks') ) {
#
#            # Copy the file handle for the peaks file into
#            # $peaks_file
#            my $peaks_file = $upload->filename;
#
#            # Create a string for the path of the peaks file
#            my $peaks_fh = "$FindBin::Bin/../tmp/upload/$peaks_file";
#
#            # Ensure that the file is copied to the temporary
#            # location
#            unless ( $upload->link_to($peaks_fh) ||
#                $upload->copy_to($peaks_fh) ) {
#                $c->stash(
#                    template    =>  
#                        'chip_primer_design.tt',
#                        
#                    error_msg   =>  
#                    ["Failed to copy '$peaks_file' to  '$peaks_fh': $!"],
#                    
#                    motifs      =>
#                        $c->model('AvailableMotifs')->available_motifs,
#
#                    genomes     =>
#                        $c->model('PrimerDesign::chipPrimerDesign::AvailableGenomes')->installed_genomes,
#                );
#            }
#
#            # Create an instance of FoxPrimer::Model::PrimerDesign and run
#            # the 'validate_chip_form subroutine to determine if the form
#            # has been filled out correctly by the user.
#            my $primer_design = $c->model('PrimerDesign')->new(
#                genome                  =>
#                    $c->request->parameters->{genome},
#
#                product_size            =>
#                    $c->request->parameters->{product_size},
#
#                motif                   =>
#                    $c->request->parameters->{known_motif},
#
#                chip_primer_coordinates =>  $peaks_fh,
#            );
#            my $form_errors = $primer_design->validate_chip_form;
#
#            # If there are any errors in the form, cease ChIP primer design
#            # and return the errors to the user.
#            if (@$form_errors) {
#                $c->stash(
#                    template    =>  
#                        'chip_primer_design.tt',
#                        
#                    error_msg   =>  $form_errors,
#                    
#                    motifs      =>
#                        $c->model('AvailableMotifs')->available_motifs,
#
#                    genomes     =>
#                        $c->model('PrimerDesign::chipPrimerDesign::AvailableGenomes')->installed_genomes,
#                );
#
#            } else {
#
#                # Run the valid_bed_file subroutine to extract the
#                # coordinates for ChIP primer design while validating the
#                # coordinates found on each line.
#                my ($bed_file_errors, $bed_file_coordinates) =
#                $primer_design->valid_bed_file;
#
#                # Make sure that there are valid BED coordinates returned
#                if ( @$bed_file_coordinates ) {
#
#                    # Create an instance of
#                    # FoxPrimer::Model::PrimerDesign::chipPrimerDesign and
#                    # run the 'design_primers' subroutine to return an
#                    # Array Ref of primers to be returned to the user.
#                    my $chip_primer_design =
#                    $c->model('PrimerDesign::chipPrimerDesign')->new(
#                        genome          =>  
#                            $c->request->parameters->{genome},
#
#                        product_size    =>
#                            $c->request->parameters->{product_size},
#
#                        motif           =>
#                            $c->request->parameters->{known_motif},
#
#                        bed_coordinates =>  $bed_file_coordinates,
#                    );
#                } else {
#
#                    # If there were no valid BED file coordinates returned,
#                    # return an error message to the Template Toolkit form
#                    # and cease execution.
#                    $c->stash(
#                        template    =>  
#                            'chip_primer_design.tt',
#                            
#                        error_msg   =>  $bed_file_errors,
#                        motifs      =>
#                            $c->model('AvailableMotifs')->available_motifs,
#
#                        genomes     =>
#                        $c->model('PrimerDesign::chipPrimerDesign::AvailableGenomes')->installed_genomes,
#                    );
#                }
#            }
##
##           # Pre-declare a hash reference called $structure,
##           # which will hold all of the variables passed to
##           # the Catalyst Model
##           my $structure = {};
##
##           # Pre-declare an Array Ref to hold error messages
##           # to return to the user.
##           my $error_messages = [];
##
##           # Use the Catalyst Model ChIP_Primer_Design to
##           # determine if the product size field is valid.
##           my $product_size_errors = 
##           $c->model('ChIP_Primer_Design')->validate_product_size($c->request->parameters);
##           if (@$product_size_errors) {
##               $c->stash(
##                   template    =>
##                       'chip_primer_design.tt',
##
##                   error_msg   =>
##                       $product_size_errors,
##
##                   motifs      =>
##                       $c->model('Available_Motifs')->available_motifs,
##               );
##           } else {
##
##               # Store the validated product size string
##               # in the structure Hash Ref
##               $structure->{product_size} = $c->request->parameters->{product_size};
##           }
##           
##           # Pre-declare a string to  hold the type of peaks found.
##           my $peaks_type = '';
##           
##           # Check to make sure the file uploaded is a valid
##           # BED file, and determine whether the coordinates
##           # are peaks or summits. 
##           my $bed_file_check =
##               $c->model('ChIP_Primer_Design')->new(
##                   genome      =>  
##                       $c->request->parameters->{genome},
##
##                   product_size    =>  
##                       $structure->{product_size},
##           );
##           my ($bed_file_errors, $bed_file_coordinates) =
##           $bed_file_check->valid_bed_file($peaks_fh);
##
##           # If none of the bed file lines were valid return
##           # the errors to the user.
##           unless ( @$bed_file_coordinates ) {
##               $c->stash(
##                   template    =>
##                       'chip_primer_design.tt',
##
##                   error_msg   =>
##                       $bed_file_errors,
##
##                   motifs      =>
##                       $c->model('Available_Motifs')->available_motifs,
##               );
##           }
##
##           # Otherwise, if any lines in the bed file contained
##           # errors, add them to the array of error messages
##           # to be returned to the user later.
##           push(@$error_messages, @$bed_file_errors) if
##           @$bed_file_errors;
##
##           # Store the peaks file location in the Structure to
##           # be passed to the Catalyst Model.
##           $structure->{peaks_file} = $peaks_fh;
##
##           # If the peaks are intervals, check to see if the
##           # user has chosen a motif from the list.
##           $structure->{motif_name} =
##               $c->request->parameters->{known_motif};
##           if ( $c->request->parameters->{known_motif} 
##               ne 'No Motif' ) {
##
##               # Retreive the motif file path from the
##               # Catalyst Model Available_Motifs and store
##               # it in the Structure.
##               $structure->{motif_file} =
##               $c->model('Available_Motifs')->motif_index->{$c->request->parameters->{known_motif}};
##           }
##
##           # Pre-declare a Hash Ref to hold the Hash Refs of
##           # coordinates to design primers.
##           my $coordinates_for_primer_design = [];
##
##           # If the primers will be designed around motifs,
##           # determine the positions of the motifs within each
##           # interval using FIMO Predeclare an Array Reference
##           # to hold the locations where a motif is not
##           # found.
##           my $no_motif_locations = [];
##           if ( $structure->{motif_name} ne 'No Motif') {
##               # Iterate through the BED file, calling
##               # FIMO with the user-designated motif. If
##               # no motif is discovered in the interval
##               # return these coordinates to the user in
##               # the error message.
##               #
##               # Make a call to the Catalyst Model for
##               # FIMO for each interval.
##               foreach my $coordinate_set
##                   (@$bed_file_coordinates) {
##                   my $fimo = $c->model('FIMO')->new(
##                       peak_name   =>
##                           $coordinate_set->{peak_name},
##
##                       chromosome  =>  
##                           $coordinate_set->{chromosome},
##
##                       start       =>  
##                           $coordinate_set->{genomic_dna_start},
##
##                       stop        =>  
##                           $coordinate_set->{genomic_dna_stop},
##
##                       motif_name  =>  
##                           $structure->{motif_name},
##
##                       genome      =>  
##                           $c->request->parameters->{genome},
##
##                       product_size    =>  
##                           $structure->{product_size},
##                   );
##                   my $motif_regions_found =
##                       $fimo->run;
##                   if (@$motif_regions_found) {
##                       push(@$coordinates_for_primer_design, 
##                           @$motif_regions_found
##                       );
##                   } else {
##                       push(@$no_motif_locations, 
##                           $coordinate_set
##                       );
##                   }
##               }
##
##               # For each interval where a motif is not
##               # found, add to the error string.
##               if ($no_motif_locations) {
##                   foreach my $not_designed
##                   (@$no_motif_locations) {
##                       push(@$error_messages, 
##                           "The motif " .
##                           $structure->{motif_name}
##                           . " was not found "
##                           . "in the peak " .
##                           $not_designed->{peak_name}
##                           . " which is on " . 
##                           $not_designed->{chromosome}
##                           . " between positions " 
##                           . $not_designed->{genomic_dna_start} 
##                           . " and " . 
##                           $not_designed->{genomic_dna_stop}.
##                           "."
##                       );
##                   }
##               }
##
##               # If there are no motifs discovered in the
##               # intervals specified return the
##               # peak_names_with_no_motif string in the
##               # error_msg.
##               unless (@$coordinates_for_primer_design) {
##                   $c->stash(
##                       template    =>  
##                           'chip_primer_design.tt',
##
##                       error_msg   =>  
##                           $error_messages,
##
##                       motifs      =>  
##                           $c->model('Available_Motifs')->available_motifs,
##                   );
##               }
##           } else {
##
##               # Copy the $bed_file_coordinates into
##               # coordinates_for_primer_design.
##               $coordinates_for_primer_design =
##               $bed_file_coordinates;
##           }
##
##           # Create an Array Ref to hold the locations where
##           # primers were unable to be designed.
##           my $unable_to_make_primers = [];
##
##           # Create an Array Ref to hold designed primers.
##           my $designed_primers = [];
##
##           # Design primers by passing the relevant
##           # information to the Catalyst Model
##           # ChIP_Primer_Design Primers will only be designed
##           # for matched motif regions, if a motif was
##           # specified.
##           foreach my $location_to_design
##           (@$coordinates_for_primer_design) {
##               my $chip_primer_design =
##               $c->model('ChIP_Primer_Design')->new(
##                   chromosome  =>  
##                       $location_to_design->{chromosome},
##
##                   start       =>  
##                       $location_to_design->{genomic_dna_start},
##
##                   stop        =>  
##                       $location_to_design->{genomic_dna_stop},
##
##                   peak_name   =>  
##                       $location_to_design->{peak_name},
##
##                   product_size    =>  
##                       $structure->{product_size},
##
##                   genome      =>  
##                       $c->request->parameters->{genome},
##               );
##               my $created_chip_primers = $chip_primer_design->design_primers;
##
##               # If primer have been designed, add them to
##               # the designed_primers Array Ref.
##               if ( %$created_chip_primers ) {
##                   push (@$designed_primers, 
##                       $created_chip_primers
##                   );
##
##               # If primers were not made, pass the
##               # location coordinates information to the
##               # unable_to_make_primers Array Ref.
##               } else {
##                   push (@$unable_to_make_primers, 
##                       $location_to_design
##                   );
##               }
##           }
##
##           # For each interval where primers were unable to be
##           # made, add an error message to the error messages
##           # to be returned to the user.
##           if ( $unable_to_make_primers ) {
##               foreach my $not_designed
##               (@$unable_to_make_primers) {
##                   push(@$error_messages, 
##                       "Primers were not able " .
##                       "to be designed for the " .
##                       "specified product size " .
##                       "in the interval " .
##                       $not_designed->{peak_name}
##                       . " which is on " .
##                       $not_designed->{chromosome}
##                       . " between positions " .
##                       $not_designed->{genomic_dna_start} 
##                       . " and " . 
##                       $not_designed->{genomic_dna_stop} .
##                       "."
##                   );
##               }
##           }
##
##           # If no primers are designed return an error
##           # message to the user.
##           unless (@$designed_primers) {
##               $c->stash(
##                   template    =>  
##                       'chip_primer_design.tt',
##
##                   error_msg   =>  
##                       $error_messages,
##
##                   motifs      =>  
##                       $c->model('Available_Motifs')->available_motifs,
##               );
##           }
##
##           # Enter the primers into the general table in the
##           # ChIP_Primers database.
##           my $chip_primers_rs =
##           $c->model('Created_ChIP_Primers::ChipPrimerPairsGeneral');
##
##           # Create an Array Ref of Hash Refs to hold the
##           # created primer information.
##           my $created_primers_insert = [];
##
##           # Store the relevant information in the Array Ref
##           # of Hash Refs.
##           foreach my $designed_primer (@$designed_primers) {
##               foreach my $primer_pair ( keys
##                   %$designed_primer ) {
##                   push(@$created_primers_insert,
##                       {
##                           left_primer_sequence        =>  
##                               $designed_primer->{$primer_pair}->{left_primer_sequence},       
##
##                           right_primer_sequence       =>  
##                               $designed_primer->{$primer_pair}->{right_primer_sequence},
##
##                           left_primer_tm          =>  
##                               $designed_primer->{$primer_pair}->{left_primer_tm},
##
##                           right_primer_tm         =>  
##                               $designed_primer->{$primer_pair}->{right_primer_tm},
##
##                           chromosome          =>  
##                               $designed_primer->{$primer_pair}->{chromosome},
##
##                           left_primer_five_prime      =>  
##                               $designed_primer->{$primer_pair}->{left_primer_5prime},
##
##                           left_primer_three_prime     =>  
##                               $designed_primer->{$primer_pair}->{left_primer_3prime},
##
##                           right_primer_five_prime     =>  
##                               $designed_primer->{$primer_pair}->{right_primer_5prime},
##
##                           right_primer_three_prime    =>  
##                               $designed_primer->{$primer_pair}->{right_primer_3prime},
##
##                           product_size            =>  
##                               $designed_primer->{$primer_pair}->{product_size},
##
##                           primer_pair_penalty     =>  
##                               $designed_primer->{$primer_pair}->{product_penalty},
##                       }
##                   );
##               }
##           }
##
##           # Insert the created primers into the database.
##           foreach my $created_primer_insert (
##               @$created_primers_insert ) {
##               $chip_primers_rs->update_or_create($created_primer_insert);
##
##               # Retrieve the primer pair id where the
##               # primers were entered.
##               my $primer_pair_row =
##               $chip_primers_rs->find(
##                   {
##                       left_primer_sequence    =>  
##                           $created_primer_insert->{left_primer_sequence},
##
##                       right_primer_sequence   =>  
##                           $created_primer_insert->{right_primer_sequence},
##                   }
##               );
##               $created_primer_insert->{primer_pair_id} =
##               $primer_pair_row->id;
##           }
##
##           # Use FoxPrimer::PeaksToGenes (a special version of
##           # PeaksToGenes) to determine the positions of the
##           # primer pairs relative to transcriptional start
##           # sites within 100Kb.
##           my $peaks_to_genes =
##           $c->model('PeaksToGenes')->new(
##               genome      =>  
##                   $c->request->parameters->{genome},
##
##               primer_info =>  
##                   $created_primers_insert,
##           );
##           my $primer_pairs_locations =
##           $peaks_to_genes->annotate_primer_pairs;
##
##           # Test to ensure that the primer pair was mapped to
##           # a relative position.
##           foreach my $created_primer_insert (
##               @$created_primers_insert ) {
##               if (
##                   $primer_pairs_locations->{$created_primer_insert->{primer_pair_id}}
##               ) {
##                   # Extract the relative location id
##                   # from the relative_location
##                   # database.
##                   my $locations_result_set =
##                   $c->model('Created_ChIP_Primers::RelativeLocation');
##                   foreach my $primer_pair_position (
##                       @{$primer_pairs_locations->{$created_primer_insert->{primer_pair_id}}}
##                   ) {
##                       my $location_row =
##                       $locations_result_set->find(
##                           {
##                               location    =>  
##                                   $primer_pair_position,
##                           }
##                       );
##                       push(@{$created_primer_insert->{relative_locations_id}}, 
##                           $location_row->id
##                       );
##                       push(@{$created_primer_insert->{relative_locations_raw_strings}}, 
##                           $location_row->location
##                       );
##                   }
##
##                   # Test to ensure that a relative
##                   # location id has been retrieved.
##                   if (
##                       @{$created_primer_insert->{relative_locations_id}}
##                   ) {
##                       my
##                       $chip_primer_pair_relative_location_result_set
##                       =
##                       $c->model('Created_ChIP_Primers::ChipPrimerPairsRelativeLocation');
##                       foreach my
##                       $relative_location_id (
##                           @{$created_primer_insert->{relative_locations_id}}
##                       ) {
##                           $chip_primer_pair_relative_location_result_set->update_or_create(
##                               {
##                                   pair_id     =>  
##                                       $created_primer_insert->{primer_pair_id},
##
##                                   location_id =>  
##                                       $relative_location_id,
##                               }
##                           );
##                       }
##                   } else {
##                       push(@{$created_primer_insert->{relative_locations}}, 
##                           "There were no " .
##                           "gene bodies " .
##                           "within 100Kb " .
##                           "of this primer" . 
##                           "pair."
##                       );
##                   }
##               } else {
##                   push(@{$created_primer_insert->{relative_locations}},
##                       "There were no gene " .
##                       "bodies within 100Kb " .
##                       "of this primer pair."
##                   );
##               }
##           }
##
##           # Use the define_relative_position subroutine from
##           # the ChIP_Primer_Design Model to determine the
##           # base position for each primer pair relative to
##           # the transcriptional start site of all transcripts
##           # within 100Kb.
##           my $define_relative_positions =
##           $c->model('ChIP_Primer_Design')->new(
##               genome  =>
##                   $c->request->parameters->{genome},
##           );
##           $created_primers_insert =
##           $define_relative_positions->define_relative_position($created_primers_insert);
##
##           # Remove the uploaded peaks file
##           unlink($peaks_fh);
##           # `rm $peaks_fh`;
##
##           # Check to see if there are any error messages to
##           # return to the user.
##           if ( @$error_messages ) {
##               $c->stash(
##                   template    =>  
##                       'chip_primer_design.tt',
##
##                   error_msg   =>  
##                       $error_messages,
##
##                   status_msg  =>  
##                       "Primers have been designed",
##
##                   motifs      =>  
##                       $c->model('Available_Motifs')->available_motifs,
##
##                   primers     =>  
##                       $created_primers_insert,
##               );
##           } else {
##
##               # If there are no error messages, inform
##               # the user that primers have been designed
##               # for all intervals, and return the primers
##               # to the user.
##               $c->stash(
##                   template    =>  
##                       'chip_primer_design.tt',
##
##                   status_msg  =>  
##                       "Primers have been designed for all intervals",
##
##                   motifs      =>  
##                       $c->model('Available_Motifs')->available_motifs,
##
##                   primers     =>  
##                       $created_primers_insert,
##               );
##           }
#        } else {
#
#            # If a file has not been uploaded, inform the user
#            # that they must upload a BED file of coordinates
#            # for which to design ChIP primers
#            $c->stash(
#                template    =>  
#                    'chip_primer_design.tt',
#
#                error_msg   =>  
#                    'You must upload a BED file of coordinates.',
#
#                motifs      =>  
#                    $c->model('AvailableMotifs')->available_motifs,
#
#                genomes     =>
#                    $c->model('PrimerDesign::chipPrimerDesign::AvailableGenomes')->installed_genomes,
#            );
#        }
#    } else {
#
#        # If a file has not been uploaded inform the user that they
#        # must upload a BED file of coordinates for which to design
#        # ChIP primers
#        $c->stash(
#            template    =>  
#                'chip_primer_design.tt',
#
#            error_msg   =>  
#                'You must upload a BED file of coordinates.',
#
#            motifs      =>  
#                $c->model('AvailableMotifs')->available_motifs,
#
#            genomes     =>
#                $c->model('PrimerDesign::chipPrimerDesign::AvailableGenomes')->installed_genomes,
#        );
#    }
#}

=head2 validated_primers_entry_shell

This subroutine creates the default form for the entry of validated primers
into the FoxPrimer database.

=cut

#sub validated_primers_entry_shell :Local {
#    my ($self, $c) = @_;
#    $c->stash(
#            template    =>  'validated_primers.tt',
#            status_msg  =>  
#                'Please fill out the form below to enter validated primers',
#    );
#}

=head2 validated_primers_entry

This is the hidden subroutine, which accepts the file uploaded by the user.
The data in the file is checked for accuracy and content before being sent
to the business model to validate the primers, and store them in the
validated primers database.

=cut

#sub validated_primers_entry :Chained('/') :PathPart('validated_primers_entry') :Args(0) {
#    my ($self, $c) = @_;
#
#    # Check to make sure that the form has been submitted
#    if ( $c->request->parameters->{form_submit} eq 'yes' ) {
#
#        # Check to make sure that the file of primers has been
#        # uploaded
#        if ( my $upload = $c->request->upload('primer_file') ) {
#
#            # Copy the primers file to the temporary storage
#            # location and store the path to the temporary file
#            # in a scalar string
#            my $primers_file = $upload->filename;
#            my $target = "tmp/upload/$primers_file";
#
#            # If there is a problem storing the file in the
#            # temporary location, cease execution and return
#            # an error message to the user.
#            unless ( $upload->link_to($target) ||
#                $upload->copy_to($target) ) {
#                $c->stash(
#                    template    =>  
#                        'validated_primers.tt',
#
#                    error_msg   =>  
#                        "Failed to copy " .
#                        $primers_file .
#                           " to " .  $target .
#                          " $!",
#                );
#            }
#
#            # Check that the file contains valid information
#            # and extract the relevant information using the
#            # Catalyst Model.
#            my ($structure, $error_messages) =
#            $c->model('Validated_Primer_Entry')->valid_file($target);
#
#            # Remove the uploaded file as it is no longer
#            # necessary.
#            # `rm $target`;
#            unlink($target);
#
#            # If no primers will be designed return the error
#            # string to the user.
#            unless ( $structure->{mrna_primers_to_design} ||
#                $structure->{chip_primers_to_design} ) {
#                my $error_string = 
#                "Unable to enter validated primers for " .
#                "the following reasons:\n" . 
#                join("\n", @$error_messages);
#                $c->stash(
#                    template    =>  'validated_primers.tt',
#                    error_msg   =>  $error_string,
#                );
#            }
#
#            # If there were no problems uploading the file and
#            # storing the primers, return a message to the
#            # user.
#            $c->stash(
#                template    =>  
#                    'validated_primers.tt',
#
#                status_msg  =>  
#                    "The file $primers_file was properly uploaded",
#            );
#        } else {
#
#            # If a file is not uploaded, return a message to
#            # the user.
#            $c->stash(
#                template    =>  
#                    'validated_primers.tt',
#
#                error_msg   =>  
#                    "You must enter a file to upload",
#            );
#        }
#    } else {
#
#        # If the user has entered the form without uploading a
#        # file, return an error message informing them.
#        $c->stash(
#            template    =>  'validated_primers.tt'.
#            error_msg   =>  
#                "You have not entered file to upload",
#        );
#    }
#}

=head2 default

Standard 404 error page if a user tries to navigate to a page, which does
not exist.

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
