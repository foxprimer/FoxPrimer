package FoxPrimer::Controller::Root;
use Moose;
use namespace::autoclean;
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

    # Load the default page for FoxPrimer. This page will display
	# the default page for the application, with brief descriptions 
	# of methods and usage for the application.
    $c->stash(
		template	=>	'home.tt',
		status_msg		=>	'Welcome to the FoxPrimer qPCR Primer Design Suite!',
	);
}

=head2 mrna_primer_design_shell

Form for entering mRNA accessions and returning designed primers
to the user.

=cut

sub mrna_primer_design_shell :Local {
	my ($self, $c) = @_;
	$c->stash(
			template	=>	'mrna_primer_design.tt',
			status_msg	=>	'Please fill out the form below to begin making primers',
	);
}

=head2 mrna_primer_design

This is the hidden subroutine/webpage, which checks the information entered by
the user and sends it to the business model to be processed and returned.

=cut

sub mrna_primer_design :Chained('/') :PathPart('mrna_primer_design') :Args(0) {
	# Default paramets passed to a zero-argument part path
	my ($self, $c) = @_;
	# Predeclare the structure which we will place all the variables
	# from the body of the HTML
	my $structure;
	$structure->{species}		=	$c->req->body_params->{species};
	$structure->{genes}			=	$c->req->body_params->{genes};
	# remove whitespace from the genes field
	$structure->{genes} =~ s/\s//g;
	# if the user has entered a blank field in the genes field
	# return an error
	if ( $structure->{genes} eq '' ) {
		$c->stash(
				error_msg	=>	'You must enter an NCBI mRNA accession',
				template	=>	'mrna_primer_design.tt',
		);
	} else {
		# predeclare an arrayref to hold the list of ncbi accessions
		my $genes = [];
		# if there is more than one accession listed, split them by
		# the comma-delimiter
		if ($structure->{genes} =~ /,/) {
			my @temp_genes = split(/,/, $structure->{genes});
			foreach my $temp_gene(@temp_genes) {
				push (@$genes, $temp_gene);
			}
		} else {
			push (@$genes, $structure->{genes});
		}
		$structure->{accessions} = $genes;
		if ($structure->{accessions} eq '') {
			$c->stash(
			error_msg	=>	'You must enter an NCBI mRNA accession',
			template	=>	'mrna_primer_design.tt',
			);
		} else {
			$structure->{product_size}	=	$c->req->body_params->{product_size};
			# remove whitespace from the product size field
			$structure->{product_size} =~ s/\s//g;
			# predeclare variables for the minimum and maximum product sizes defined
			# in the product size field 
			my ($product_min, $product_max);
			# use regular expressions to extract min and max product sizes from the
			# product size field
			if ($structure->{product_size} =~ /^(\d+)-(\d+)$/) {
				$product_min = $1;
				$product_min = int($product_min + 0.5);
				$product_max = $2;
				$product_max = int($product_max + 0.5);
				$structure->{intron_size} = $c->req->body_params->{intron_size};
				# remove whitespace from the intron size field
				$structure->{intron_size} =~ s/\s//g;
				# test the intron size field to ensure that it is an integer
				if ( $structure->{intron_size} =~ /^\d+$/ ) {
					$structure->{number_per_type} = $c->req->body_params->{number_per_type};
					# remove whitespace from the number per type field
					$structure->{number_per_type} =~ s/\s//g;
					# test the number per type field to ensure that it is an integer
					unless ( $structure->{number_per_type} =~ /^\d+$/ ) {
						$c->stash(
								error_msg	=>	"You must enter an integer value as the number per type",
								templare	=>	'mrna_primer_design.tt',
						);
					}
					# This subroutine checks the database of accessions, gis and genomic
					# coordinates for the user-entered accessions, returns an arrayref of
					# accessions not found in the database
					my $valid_accessions = {};
					my $list_of_found_accessions = {};
					my $invalid_accessions = [];
					my $rs = $c->model('Valid_mRNA::Gene2accession')->search({
							-or	=>	[
								'mrna'		=>	[@$genes],
								'mrna_root'	=>	[@$genes],
							],
						}
					);
					while ( my $result = $rs->next ) {
						unless ( defined ( $list_of_found_accessions->{$result->mrna} ) ) {
							$list_of_found_accessions->{$result->mrna} = 1;
						}
						unless ( defined ( $list_of_found_accessions->{$result->mrna_root} ) ) {
							$list_of_found_accessions->{$result->mrna_root} = 1;
						}
						push ( @{$valid_accessions->{$result->mrna}}, join("\t", $result->mrna, $result->mrna_gi, $result->dna_gi,
							$result->dna_start, $result->dna_stop, $result->orientation));
					}
					$structure->{valid_accessions} = $valid_accessions;
					# if accessions are not found in the database they are returned to the
					# user as a string of accessions in the error message field. If any
					# accessions entered are valid, these are sent to the create primers
					# subroutine and the results are returned to the user.
					foreach my $gene (@$genes) {
						unless ( defined( $list_of_found_accessions->{$gene} ) ) {
							push (@$invalid_accessions, $gene);
						}
					}
					if ( %$valid_accessions ) {
						my $number_of_valid_accessions = 0;
						foreach my $valid_accession ( keys $valid_accessions ) {
							$number_of_valid_accessions++;
						}
						my $total_number_to_make = @$genes;
						if ( $number_of_valid_accessions == $total_number_to_make ) {
							my $return_accessions = $c->model('mRNA_Primer_Design')->create_primers($structure);
							`rm temp.out`;
							my $primer_results = $c->model('Created_Primers::Primer')->search(
										{ 'mrna'	=>	$return_accessions },
										{ order_by	=>	{ -asc	=>	'product_penalty'} }
									);
							$c->stash(
									structure		=>	$structure,
									primer_results	=>	$primer_results,
									template		=>	'mrna_primer_design.tt',
									status_msg		=>	'Your primers have been designed!',
							);
						} else {
							my $error_string = join(", ", @$invalid_accessions);
							my $return_accessions = $c->model('mRNA_Primer_Design')->create_primers($structure);
							my $primer_results = $c->model('Created_Primers::Primer')->search(
										{ 'mrna'	=>	$return_accessions },
										{ order_by	=>	{ -asc	=>	'product_penalty'} }
									);
							$c->stash(
									structure		=>	$structure,
									error_msg		=>	"Unfortunately, the following accessions were not found in our NCBI:gene2accession database: $error_string",
									status_msg		=>	"Your primers have been designed!",
									primer_results	=>	$primer_results,
									template		=>	'mrna_primer_design.tt',
							);
						}
					} else {
						my $error_string = join(", ", @$invalid_accessions);
						$c->stash(
							template		=>	'mrna_primer_design.tt',
							error_msg		=>	"Unfortunately, the following accessions were not found in our NCBI:gene2accession database: $error_string",
						);
					}
				} else {
					$c->stash(
								error_msg	=>	"You must enter an integer value for the intron size",
								template	=>	'mrna_primer_design.tt',
					);
				}
			} else {
				$c->stash(
						error_msg	=>	"You must enter integer values for the product sizes and the product min and product max seperated by a hyphen '-'.",
						template	=>	'mrna_primer_design.tt',
				);
			}
		}
	}
}

=head2 chip_primer_design_shell

This is the form to enter information for the design of ChIP primers.

=cut

sub chip_primer_design_shell :Local {
	my ($self, $c) = @_;
	$c->stash(
			template	=>	'chip_primer_design.tt',
			status_msg	=>	'Please fill out the form below to begin making primers',
			motifs		=>	$c->model('Available_Motifs')->available_motifs,
	);
}


=head2 chip_primer_design

This is the hidden subroutine to design ChIP primers for the user. It uses a file of
BED coordinates uploaded by the user to design primers for qPCR. Primers can be designed
to flank either a motif or a peak summit.

=cut

sub chip_primer_design :Chained('/') :PathPart('chip_primer_design') :Args(0) {
	my ($self, $c) = @_;
	# Check to see that the form has been submitted.
	if ( $c->request->parameters->{peaks_submit} eq 'yes' ) {
		# Check to make sure that a peaks file has been uploaded
		if ( my $upload = $c->request->upload('peaks') ) {
			# Copy the file handle for the peaks file into $peaks_file
			my $peaks_file = $upload->filename;
			# Create a string for the path of the peaks file
			my $peaks_fh = "tmp/upload/$peaks_file";
			# Ensure that the file is copied to the temporary location
			unless ( $upload->link_to($peaks_fh) || $upload->copy_to($peaks_fh) ) {
				$c->stash(
					template	=>	'chip_primer_design.tt',
					error_msg	=>	["Failed to copy '$peaks_file' to  '$peaks_fh': $!"],
					motifs		=>	$c->model('Available_Motifs')->available_motifs,
				);
			}
			# Pre-declare a hash reference called $structure, which will hold all of the variables passed to the Catalyst Model
			my $structure = {};
			# Pre-declare an Array Ref to hold error messages to return to the user
			my $error_messages = [];
			# Use the Catalyst Model ChIP_Primer_Design to determine if the product size field is valid
			my $product_size_errors = $c->model('ChIP_Primer_Design')->validate_product_size($c->request->parameters);
			if (@$product_size_errors) {
				$c->stash(
					template	=>	'chip_primer_design.tt',
					error_msg	=>	$product_size_errors,
					motifs		=>	$c->model('Available_Motifs')->available_motifs,
				);
			} else {
				$structure->{product_size} = $c->request->parameters->{product_size};
			}
			# Check to make sure the file uploaded is a valid BED file, and determine whether the coordinates are peaks or summits.
			# Pre-declare a string to hold the type of peaks found.
			my $peaks_type;
			
			my $bed_file_check = $c->model('ChIP_Primer_Design')->new(
				genome			=>	$c->request->parameters->{genome},
				product_size	=>	$structure->{product_size},
			);
			my ($bed_file_errors, $bed_file_coordinates) = $bed_file_check->valid_bed_file($peaks_fh);
			# If none of the bed file lines were valid return the errors to the user
			unless ( @$bed_file_coordinates ) {
				$c->stash(
					template	=>	'chip_primer_design.tt',
					error_msg	=>	$bed_file_errors,
					motifs		=>	$c->model('Available_Motifs')->available_motifs,
				);
			}
			# Otherwise, if any lines in the bed file contained errors, add them to the
			# array of error messages to be returned to the user later
			push(@$error_messages, @$bed_file_errors) if @$bed_file_errors;
			# Store the peaks file location in the Structure to be passed to the Catalyst Model
			$structure->{peaks_file} = $peaks_fh;
			# If the peaks are intervals, check to see if the user has chosen a motif from the list
			if ( $c->request->parameters->{known_motif} ) {
				# Retreive the motif file path from the Catalyst Model Available_Motifs and store it in the Structure
				$structure->{motif_file} = $c->model('Available_Motifs')->motif_index->{$c->request->parameters->{known_motif}};
				$structure->{motif_name} = $c->request->parameters->{known_motif};
			}
			# Pre-declare a Hash Ref to hold the Hash Refs of coordinates to design primers
			my $coordinates_for_primer_design = [];
			# If the primers will be designed around motifs, determine the positions of the motifs within each interval using FIMO
			# Predeclare an Array Reference to hold the locations where a motif is not found.
			my $no_motif_locations = [];
			if ( $structure->{motif_name} ) {
				# Iterate through the BED file, calling FIMO with the user-designated motif. If no motif is discovered in the interval
				# return these coordinates to the user in the error message
				# Make a call to the Catalyst Model for FIMO for each interval
				foreach my $coordinate_set (@$bed_file_coordinates) {
					my $fimo = $c->model('FIMO')->new(
						peak_name		=>	$coordinate_set->{peak_name},
						chromosome		=>	$coordinate_set->{chromosome},
						start			=>	$coordinate_set->{genomic_dna_start},
						stop			=>	$coordinate_set->{genomic_dna_stop},
						motif_name		=>	$structure->{motif_name},
						genome			=>	$c->request->parameters->{genome},
						product_size	=>	$structure->{product_size},
					);
					my $motif_regions_found = $fimo->run;
					if (@$motif_regions_found) {
						push(@$coordinates_for_primer_design, @$motif_regions_found);
					} else {
						push(@$no_motif_locations, $coordinate_set);
					}
				}
				# For each interval where a motif is not found, add to the error string
				if (@$no_motif_locations) {
					foreach my $not_designed (@$no_motif_locations) {
						push(@$error_messages, "The motif $structure->{motif_name} was not found in the peak $not_designed->{peak_name} which is on $not_designed->{chromosome} between positions $not_designed->{genomic_dna_start} and $not_designed->{genomic_dna_stop}.");
					}
				}
				# If there are no motifs discovered in the intervals specified return the 
				# peak_names_with_no_motif string in the error_msg
				unless (@$coordinates_for_primer_design) {
					$c->stash(
						template	=>	'chip_primer_design.tt',
						error_msg	=>	$error_messages,
						motifs		=>	$c->model('Available_Motifs')->available_motifs,
					);
				}
			} else {
				# Copy the $bed_file_coordinates into coordinates_for_primer_design
				$coordinates_for_primer_design = $bed_file_coordinates;
			}
			# Create an Array Ref to hold the locations where primers were unable to be designed
			my $unable_to_make_primers = [];
			# Create an Array Ref to hold designed primers
			my $designed_primers = [];
			# Design primers by passing the relevant information to the Catalyst Model ChIP_Primer_Design
			# Primers will only be designed for matched motif regions, if a motif was specified.
			foreach my $location_to_design (@$coordinates_for_primer_design) {
				my $chip_primer_design = $c->model('ChIP_Primer_Design')->new(
					chromosome			=>	$location_to_design->{chromosome},
					start				=>	$location_to_design->{genomic_dna_start},
					stop				=>	$location_to_design->{genomic_dna_stop},
					peak_name			=>	$location_to_design->{peak_name},
					product_size		=>	$structure->{product_size},
					genome				=>	$c->request->parameters->{genome},
				);
				my $created_chip_primers = $chip_primer_design->design_primers;
				# If primer have been designed, add them to the designed_primers
				# Array Ref
				if ( %$created_chip_primers ) {
					push (@$designed_primers, $created_chip_primers);
				# If primers were not made, pass the location coordinates information
				# to the unable_to_make_primers Array Ref
				} else {
					push (@$unable_to_make_primers, $location_to_design);
				}
			}
			# For each interval where primers were unable to be made, add an error message
			# to the error messages to be returned to the user
			if ( @$unable_to_make_primers ) {
					foreach my $not_designed (@$unable_to_make_primers) {
						push(@$error_messages, "The motif $structure->{motif_name} was not found in the peak $not_designed->{peak_name} which is on $not_designed->{chromosome} between positions $not_designed->{genomic_dna_start} and $not_designed->{genomic_dna_stop}.");
					}
			}
			# If no primers are designed return an error message to the user
			unless (@$designed_primers) {
				$c->stash(
					template	=>	'chip_primer_design.tt',
					error_msg	=>	$error_messages,
					motifs		=>	$c->model('Available_Motifs')->available_motifs,
				);
			}
			# Enter the primers into the general table in the ChIP_Primers database
			my $chip_primers_rs = $c->model('Created_ChIP_Primers::ChipPrimerPairsGeneral');
			# Create an Array Ref of Hash Refs to hold the created primer information
			my $created_primers_insert = [];
			# Store the relevant information in the Array Ref of Hash Refs
			foreach my $designed_primer (@$designed_primers) {
				foreach my $primer_pair ( keys %$designed_primer ) {
					push(@$created_primers_insert,
						{
							left_primer_sequence		=>	$designed_primer->{$primer_pair}->{left_primer_sequence},		
							right_primer_sequence		=>	$designed_primer->{$primer_pair}->{right_primer_sequence},
							left_primer_tm				=>	$designed_primer->{$primer_pair}->{left_primer_tm},
							right_primer_tm				=>	$designed_primer->{$primer_pair}->{right_primer_tm},
							chromosome					=>	$designed_primer->{$primer_pair}->{chromosome},
							left_primer_five_prime		=>	$designed_primer->{$primer_pair}->{left_primer_5prime},
							left_primer_three_prime		=>	$designed_primer->{$primer_pair}->{left_primer_3prime},
							right_primer_five_prime		=>	$designed_primer->{$primer_pair}->{right_primer_5prime},
							right_primer_three_prime	=>	$designed_primer->{$primer_pair}->{right_primer_3prime},
							product_size				=>	$designed_primer->{$primer_pair}->{product_size},
							primer_pair_penalty			=>	$designed_primer->{$primer_pair}->{product_penalty},
						}
					);
				}
			}
			# Insert the created primers into the database
			foreach my $created_primer_insert ( @$created_primers_insert ) {
				$chip_primers_rs->update_or_create($created_primer_insert);
				# Retrieve the primer pair id where the primers were entered
				my $primer_pair_row = $chip_primers_rs->find(
					{
						left_primer_sequence		=>	$created_primer_insert->{left_primer_sequence},
						right_primer_sequence		=>	$created_primer_insert->{right_primer_sequence},
					}
				);
				$created_primer_insert->{primer_pair_id} = $primer_pair_row->id;
			}
			# Use FoxPrimer::PeaksToGenes (a special version of PeaksToGenes) to determine the positions of the primer pairs 
			# relative to transcriptional start sites within 100Kb
			my $peaks_to_genes = $c->model('PeaksToGenes')->new(
				genome		=>	$c->request->parameters->{genome},
				primer_info	=>	$created_primers_insert,
			);
			my $primer_pairs_locations = $peaks_to_genes->annotate_primer_pairs;
			# Test to ensure that the primer pair was mapped to a relative position
			foreach my $created_primer_insert ( @$created_primers_insert ) {
				if ( @{$primer_pairs_locations->{$created_primer_insert->{primer_pair_id}}} ) {
					# Extract the relative location id from the relative_location database
					my $locations_result_set = $c->model('Created_ChIP_Primers::RelativeLocation');
					foreach my $primer_pair_position ( @{$primer_pairs_locations->{$created_primer_insert->{primer_pair_id}}} ) {
						my $location_row = $locations_result_set->find(
							{
								location	=>	$primer_pair_position,
							}
						);
						push(@{$created_primer_insert->{relative_locations_id}}, $location_row->id);
						# Parse the primer pair position string before adding it to the insert structure
						my $parsed_position_string;
						if ( $primer_pair_position =~ /^(.+?)-Human_(.+)$|^(.+?)-Human_(.+)$/ ) {
							my $accession = $1;
							my $location = $2;
							$parsed_position_string = "$location of $accession";
							# Use the ChIP_Primer_Design define_relative_position subroutine to
							# determine the position of the 5'-end of each primer relative to the
							# transcriptional start site
							my $define_relative_position = $c->model('ChIP_Primer_Design')->new(
								genome		=>	$c->request->parameters->{genome},
								start		=>	$created_primer_insert->{left_primer_five_prime},
								stop		=>	$created_primer_insert->{right_primer_five_prime},
								chromosome	=>	$created_primer_insert->{chromosome},
							);
							my ($left_primer_relative_position_string,
								$right_primer_relative_position_string) = $define_relative_position->define_relative_position($accession);
							for ( my $i = 0; $i < @$left_primer_relative_position_string; $i++ ) {
								$parsed_position_string .= " ($left_primer_relative_position_string->[$i] to $right_primer_relative_position_string->[$i])";
							}
						}
						push(@{$created_primer_insert->{relative_locations}}, $parsed_position_string);
					}
					# Test to ensure that a relative location id has been retrieved
					if ( @{$created_primer_insert->{relative_locations_id}} ) {
						my $chip_primer_pair_relative_location_result_set = $c->model('Created_ChIP_Primers::ChipPrimerPairsRelativeLocation');
						foreach my $relative_location_id ( @{$created_primer_insert->{relative_locations_id}} ) {
							$chip_primer_pair_relative_location_result_set->update_or_create(
								{
									pair_id	=>	$created_primer_insert->{primer_pair_id},
									location_id	=>	$relative_location_id,
								}
							);
						}
					} else {
						push(@{$created_primer_insert->{relative_locations}}, "There were no gene bodies within 100Kb of this primer pair");
					}
				} else {
					push(@{$created_primer_insert->{relative_locations}}, "There were no gene bodies within 100Kb of this primer pair");
				}
			}
			`rm $peaks_fh`;
			# Check to see if there are any error messages to return to the user
			if ( @$error_messages ) {
				$c->stash(
					template	=>	'chip_primer_design.tt',
					error_msg	=>	$error_messages,
					status_msg	=>	"Primers have been designed",
					motifs		=>	$c->model('Available_Motifs')->available_motifs,
					primers		=>	$created_primers_insert,
				);
			} else {
				$c->stash(
					template	=>	'chip_primer_design.tt',
					status_msg	=>	"Primers have been designed for all intervals",
					motifs		=>	$c->model('Available_Motifs')->available_motifs,
					primers		=>	$created_primers_insert,
				);
			}
		} else {
			$c->stash(
				template	=>	'chip_primer_design.tt',
				error_msg	=>	'You must upload a BED file of coordinates.',
				motifs		=>	$c->model('Available_Motifs')->available_motifs,
			);
		}
	} else {
		$c->stash(
			template	=>	'chip_primer_design.tt',
			error_msg	=>	'You must upload a BED file of coordinates.',
			motifs		=>	$c->model('Available_Motifs')->available_motifs,
		);
	}
}

=head2 validated_primers_entry_shell

This is the form to enter primers which have been validated experimentally.

=cut

sub validated_primers_entry_shell :Local {
	my ($self, $c) = @_;
	$c->stash(
			template	=>	'validated_primers.tt',
			status_msg	=>	'Please fill out the form below to enter validated primers',
	);
}

=head2 validated_primers_entry

This is the hidden subroutine, which accepts the file uploaded by the user. The data in the file is checked
for accuracy and content before being sent to the business model to validate the primers, and store them
in the validated primers database.

=cut

sub validated_primers_entry :Chained('/') :PathPart('validated_primers_entry') :Args(0) {
	my ($self, $c) = @_;
	if ( $c->request->parameters->{form_submit} eq 'yes' ) {
		if ( my $upload = $c->request->upload('primer_file') ) {
			my $primers_file = $upload->filename;
			my $target = "tmp/upload/$primers_file";
			unless ( $upload->link_to($target) || $upload->copy_to($target) ) {
				$c->stash(
					template	=>	'validated_primers.tt',
					error_msg	=>	"Failed to copy '$primers_file' to  '$target': $!",
				);
			}
			# Check that the file contains valid information and extract the relevant information
			# using the Catalyst Model
			my ($structure, $error_messages) = $c->model('Validated_Primer_Entry')->valid_file($target);
			# Remove the uploaded file as it is no longer necesary
			`rm $target`;
			# If no primers will be designed return the error string to the user
			unless ( $structure->{mrna_primers_to_design} || $structure->{chip_primers_to_design} ) {
				my $error_string = "Unable to enter validated primers for the following reasons:\n" . join("\n", @$error_messages);
				$c->stash(
					template	=>	'validated_primers.tt',
					error_msg	=>	$error_string,
				);
			}
			$c->stash(
				template	=>	'validated_primers.tt',
				status_msg	=>	"The file $primers_file was properly uploaded",
			);
		} else {
			$c->stash(
				template	=>	'validated_primers.tt',
				error_msg	=>	"You must enter a file to upload",
			);
		}
	} else {
		$c->stash(
			template	=>	'validated_primers.tt',
			error_msg	=>	"You have not entered file to upload",
		);
	}
}

=head2 default

Standard 404 error page

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

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
