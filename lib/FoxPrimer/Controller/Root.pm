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
					error_msg	=>	"Failed to copy '$peaks_file' to  '$peaks_fh': $!",
					motifs		=>	$c->model('Available_Motifs')->available_motifs,
				);
			}
			# Check to make sure there is something in the 'Cell Line' field
			unless ( $c->request->parameters->{cell_line} ) {
				$c->stash(
					template	=>	'chip_primer_design.tt',
					error_msg	=>	'You must enter a cell line from which the coordinates were generated',
					motifs		=>	$c->model('Available_Motifs')->available_motifs,
				);
			}
			# Check to make sure there is an antibody or treatment entered
			unless ( $c->request->parameters->{antibody} ) {
				$c->stash(
					template	=>	'chip_primer_design.tt',
					error_msg	=>	'You must enter the antibody or treatment from which the coordinates were generated',
					motifs		=>	$c->model('Available_Motifs')->available_motifs,
				);
			}
			# Check to make sure the product size field is filled
			unless ( $c->request->parameters->{product_size} ) {
				$c->stash(
					template	=>	'chip_primer_design.tt',
					error_msg	=>	'You must fill the product size field',
					motifs		=>	$c->model('Available_Motifs')->available_motifs,
				);
			}
			# Predeclare a hash reference called $structure, which will hold all of the variables passed to the Catalyst Model
			my $structure = {};
			# Copy the Cell Line field into the structure
			$structure->{cell_line} = $c->request->parameters->{cell_line};
			# remove any whitespace from the Cell Line field.
			$structure->{cell_line} =~ s/\s//g;
			# Copy the antibody field into the structure
			$structure->{antibody} = $c->request->parameters->{antibody};
			# remove any whitespace from the antibody field.
			$structure->{antibody} =~ s/\s//g;
			# Copy the Product Size field into the structure
			$structure->{product_size} = $c->request->parameters->{product_size};
			# remove any whitespace from the Product Size field.
			$structure->{product_size} =~ s/\s//g;
			# Test to ensure that the numbers entered in the Product Size field are valid.
			if ( $structure->{product_size} =~ /-/ ) {
				my ($lower_limit, $upper_limit) = split(/-/, $structure->{product_size});
				unless ( ($lower_limit =~ /^\d+$/) && ($upper_limit =~ /^\d+$/) ) {
					$c->stash(
						template	=>	'chip_primer_design.tt',
						error_msg	=>	'The upper and lower limits for the product size must be integers',
						motifs		=>	$c->model('Available_Motifs')->available_motifs,
					);
				}
				unless ( $upper_limit > $lower_limit ) {
					$c->stash(
						template	=>	'chip_primer_design.tt',
						error_msg	=>	'The upper limit for the product size must be greater than the lower limit',
						motifs		=>	$c->model('Available_Motifs')->available_motifs,
					);
				}
			} else {
				$c->stash(
					template	=>	'chip_primer_design.tt',
					error_msg	=>	'The product size field must contain a hyphen "-" seperating the upper and lower product size limits',
					motifs		=>	$c->model('Available_Motifs')->available_motifs,
				);
			}
			# Check to make sure the file uploaded is a valid BED file, and determine whether the coordinates are peaks or summits.
			# Pre-declare a string to hold the type of peaks found.
			my $peaks_type;
			# Open the file, returning an error to the user if the file is not openable
			open my $bed_file, "<", $peaks_fh or $c->stash(
				template	=>	'chip_primer_design.tt',
				error_msg	=>	"The uploaded file: $peaks_fh was not able to be read. Please check permissions on the file.",
				motifs		=>	$c->model('Available_Motifs')->available_motifs,
			);
			# Initialize a line number, so if there are errors in the file, the user can be referred to the position of the error.
			my $bed_line_number = 1;
			# Pre-declare a hash reference to ensure that the peak names are unique
			my $peaks_names = {};
			while (<$bed_file>) {
				my $line = $_;
				chomp($line);
				my ($chr, $start, $stop, $name) = split(/\t/, $line);
				# Test to ensure that there is a name in the fourth field of the uploaded file.
				unless ( $name ) {
					$c->stash(
						template	=>	'chip_primer_design.tt',
						error_msg	=>	"The fourth column on line $bed_line_number of your BED file: $peaks_file must have a peak name.",
						motifs		=>	$c->model('Available_Motifs')->available_motifs,
					);
				}
				# Test to ensure that the fourth field is unique
				if ( $peaks_names->{$name} ) {
					$c->stash(
						template	=>	'chip_primer_design.tt',
						error_msg	=>	"The fourth column on line $bed_line_number of your BED file: $peaks_file must have a unique peak name.",
						motifs		=>	$c->model('Available_Motifs')->available_motifs,
					);
				} else {
					$peaks_names->{$name} = 1;
				}
				# Test to ensure that the Chromosome field begins with 'chr'
				unless ( $chr =~ /^chr/ ) {
					$c->stash(
						template	=>	'chip_primer_design.tt',
						error_msg	=>	"On line $bed_line_number of your BED file: $peaks_file, the chromosome field: $chr is not valid.",
						motifs		=>	$c->model('Available_Motifs')->available_motifs,
					);
				}
				# Test to ensure that the Start field is an integer
				unless ( $start =~ /^\d+$/ ) {
					$c->stash(
						template	=>	'chip_primer_design.tt',
						error_msg	=>	"On line $bed_line_number of your BED file: $peaks_file, the start field: $start is not an integer.",
						motifs		=>	$c->model('Available_Motifs')->available_motifs,
					);
				}
				# Test to ensure that the Stop field is an integer
				unless ( $stop =~ /^\d+$/ ) {
					$c->stash(
						template	=>	'chip_primer_design.tt',
						error_msg	=>	"On line $bed_line_number of your BED file: $peaks_file, the stop field: $stop is not an integer.",
						motifs		=>	$c->model('Available_Motifs')->available_motifs,
					);
				}
				# Test to ensure that the Stop field is larger than the Start field
				unless ( $stop > $start ) {
					$c->stash(
						template	=>	'chip_primer_design.tt',
						error_msg	=>	"On line $bed_line_number of your BED file: $peaks_file, the stop field: $stop is not large than the start field: $start.",
						motifs		=>	$c->model('Available_Motifs')->available_motifs,
					);
				}
				# Determine which type of intervals have been uploaded
				if ( ! $peaks_type ) {
					if ( ($start + 1) == $stop ) {
						$peaks_type = 'summits';
					} elsif ( $stop > ($start + 1) ) {
						$peaks_type = 'peak_regions';
					}
				} elsif ( $peaks_type eq 'summits' ) {
					unless ( ($start + 1) == $stop ) {
						$c->stash(
							template	=>	'chip_primer_design.tt',
							error_msg	=>	"On line $bed_line_number of your BED file: $peaks_file, the coordinates are not summits, which were defined by the first line in your file.",
							motifs		=>	$c->model('Available_Motifs')->available_motifs,
						);
					}
				} elsif ( $peaks_type eq 'peak_regions' ) {
					unless ( $stop > ($start + 1) ) {
						$c->stash(
							template	=>	'chip_primer_design.tt',
							error_msg	=>	"On line $bed_line_number of your BED file: $peaks_file, the coordinates are not peak regions, which were defined by the first line in your file.",
							motifs		=>	$c->model('Available_Motifs')->available_motifs,
						);
					}
				}
				# Push the interval line into the Structure to be passed to the Catalyst Model
				push (@{$structure->{bed_file}}, $line);
				# Increase the line number at the end of the loop
				$bed_line_number++;
			}
			# Store the peaks file location in the Structure to be passed to the Catalyst Model
			$structure->{peaks_file} = $peaks_fh;
			# If the peaks are intervals, check to see if the user has chosen a motif from the list
			if ( $peaks_type eq 'peak_regions' ) {
				if ( $c->request->parameters->{known_motif} ) {
					# Retreive the motif file path from the Catalyst Model Available_Motifs and store it in the Structure
					$structure->{motif_file} = $c->model('Available_Motifs')->motif_index->{$c->request->parameters->{known_motif}};
					$structure->{motif_name} = $c->request->parameters->{known_motif};
					$structure->{design_type} = 'motif';
				} else {
					$structure->{design_type} = 'region';
				}
			} else {
				$structure->{design_type} = 'summit';
			}
			# If the primers will be designed around motifs, determine the positions of the motifs within each interval using FIMO
			if ( $structure->{design_type} eq 'motif' ) {
				# Iterate through the BED file, calling FIMO with the user-designated motif. If no motif is discovered in the interval
				# return these coordinates to the user in the error message
				# Predeclare an Array Reference to hold the locations where a motif is not found.
				my $no_motif_locations = [];
				# Predeclare a Hash Reference to hold the intervals and the motif locations within each interval
				my $motif_location_hash = {};
				# Make a call to the Catalyst Model for FIMO
				foreach my $line ( @{$structure->{bed_file}} ) {
					my ($chromosome, $start, $stop, $peak_name) = split(/\t/, $line);
					my $fimo = $c->model('FIMO')->new(
						chromosome	=>	$chromosome,
						start		=>	$start,
						stop		=>	$stop,
						motif_name	=>	$structure->{motif_name},
						genome		=>	$c->request->parameters->{genome},
					);
					my ($motifs_found, $motif_positions) = $fimo->run;
					if ( $motifs_found == 1 ) {
						foreach my $motif_location_found (@$motif_positions) {
							push (@{$motif_location_hash->{$peak_name}}, $motif_location_found);
						}
					} elsif ( $motifs_found == 0 ) {
						push (@$no_motif_locations, $peak_name);
					}
				}
				# Store the motifs location hash in the $structure
				$structure->{locations_by_peak} = $motif_location_hash;
				# Store the peaks that do not contain the user-defined motif in the $structure as
				# a ", "-delimited string
				$structure->{peak_names_with_no_motif}  = join(", ", @$no_motif_locations);
				# If there are no motifs discovered in the intervals specified return the 
				# peak_names_with_no_motif string in the error_msg
				unless ( %$motif_location_hash ) {
					$c->stash(
						template	=>	'chip_primer_design.tt',
						error_msg	=>	"Unfortunately, no matches were found for the $structure->{motif_name} motif in any of these intervals $structure->{peak_names_with_no_motif}.\nPlease choose a different motif, or none to design ChIP primers in the interval.",
						motifs		=>	$c->model('Available_Motifs')->available_motifs,
					);
				}
			} else {
				# Pre-declare a temporary Hash Reference to hold locations by peak name
				my $temp_locations_by_peak_name = {};
				# Store the locations in the $structure
				foreach my $line ( @{$structure->{bed_file}} ) {
					my ($chromosome, $start, $stop, $peak_name) = split(/\t/, $line);
					$temp_locations_by_peak_name->{$peak_name} = join("\t", $chromosome, $start, $stop);
				}
				$structure->{locations_by_peak} = $temp_locations_by_peak_name;
			}
			# Create an Array Ref to hold the locations where primers were unable to be designed
			my $unable_to_make_primers = [];
			# Design primers by passing the relevant information to the Catalyst Model ChIP_Primer_Design
			# Primers will only be designed for matched motif regions, if a motif was specified.
			foreach my $design_location ( keys %{$structure->{locations_by_peak}} ) {
				foreach my $location_string (@{$structure->{locations_by_peak}->{$design_location}}) {
					my ($chromosome, $start, $stop) = split(/\t/, $location_string);
					my $chip_primer_design = $c->model('ChIP_Primer_Design')->new(
						primer_type			=>	$structure->{design_type},
						chromosome			=>	$chromosome,
						start				=>	$start,
						stop				=>	$stop,
						peak_name			=>	$design_location,
						product_size		=>	$structure->{product_size},
						genome		=>	$c->request->parameters->{genome},
					);
					my ($primers_designed_boolean, $created_chip_primers) = $chip_primer_design->design_primers;
					if ( $primers_designed_boolean == 1 ) {
						push (@$unable_to_make_primers, {$design_location	=>	$chromosome . ':' . $start . '-' . $stop});
					} else {
						# Add the created ChIP primers to the structure
						$structure->{created_chip_primers}{$design_location}{$location_string} = $created_chip_primers;
					}
				}
			}
			# Create a string to return to the user if there were regions where primers were not able to be created
			my $unable_to_make_primers_string;
			if ( @$unable_to_make_primers ) {
				foreach my $design_try ( @$unable_to_make_primers ) {
					foreach my $location ( keys %$design_try ) {
						$unable_to_make_primers_string .= "In the peak: $location, coordinates: $design_try->{$location}\n";
					}
				}
			}
			# If no primers are designed return an error message to the user
			unless ( %{$structure->{created_chip_primers}} ) {
				# Create a string to hold the error messages
				my $no_primers_designed_message = "Unfortunately, no primers were designed for the following reasons:\n";
				# If there were locations where a motif was not found, add these to the error string
				if ( $structure->{peak_names_with_no_motif} ) {
					$no_primers_designed_message .= "No matches were found for the motif $structure->{motif_name} in any of these intervals: $structure->{peak_names_with_no_motif}.\n";
				}
				# If primers were not able to be designed flanking a particular motif location, add these to the error string
				if ( @$unable_to_make_primers ) {
					$no_primers_designed_message .= "Primers were not able to be made in the following locations:\n";
					foreach my $design_try ( @$unable_to_make_primers ) {
						foreach my $location ( keys %$design_try ) {
							$no_primers_designed_message .= "In the peak: $location, coordinates: $design_try->{$location}\n";
						}
					}
				}
				$c->stash(
					template	=>	'chip_primer_design.tt',
					error_msg	=>	$no_primers_designed_message,
					motifs		=>	$c->model('Available_Motifs')->available_motifs,
				);
			}
			# Enter the primers into the general table in the ChIP_Primers database
			my $chip_primers_rs = $c->model('Created_ChIP_Primers::ChipPrimerPairsGeneral');
			foreach my $interval_name ( keys %{$structure->{created_chip_primers}} ) {
				foreach my $location_string ( keys %{$structure->{created_chip_primers}{$interval_name}} ) {
					my ($chromosome, $location_start, $location_stop) = split(/\t/, $location_string);
					foreach my $primer_pair ( keys %{$structure->{created_chip_primers}{$interval_name}{$location_string}} ) {
						$chip_primers_rs->update_or_create({
								left_primer_sequence		=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{left_primer_sequence},
								right_primer_sequence		=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{right_primer_sequence},
								left_primer_tm				=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{left_primer_tm},
								right_primer_tm				=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{right_primer_tm},
								chromosome					=>	$chromosome,
								left_primer_five_prime		=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{left_primer_5prime},
								left_primer_three_prime		=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{left_primer_3prime},
								right_primer_five_prime		=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{right_primer_5prime},
								right_primer_three_prime	=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{right_primer_3prime},
								product_size				=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{product_size},
								primer_pair_penalty			=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{product_penalty},
							}
						);
						# Retrieve the database row where the primers were entered
						my $primer_pair_row = $chip_primers_rs->find(
							{
								left_primer_sequence		=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{left_primer_sequence},
								right_primer_sequence		=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{right_primer_sequence},
							}
						);
						my $primer_pair_id = $primer_pair_row->id;
						# Use FoxPrimer::PeaksToGenes (a special version of PeaksToGenes) to determine the positions of the primer pairs 
						# relative to transcriptional start sites within 100Kb
						my $peaks_to_genes = $c->model('PeaksToGenes')->new(
							genome		=>	$c->request->parameters->{genome},
							chromosome	=>	$chromosome,
							start		=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{left_primer_5prime},
							stop		=>	$structure->{created_chip_primers}{$interval_name}{$location_string}{$primer_pair}{right_primer_5prime},
						);
						my $primer_pairs_locations = $peaks_to_genes->annotate_primer_pairs;
					}
				}
			}
			`rm $peaks_fh`;
			$c->stash(
				template	=>	'chip_primer_design.tt',
				status_msg	=>	"The file $peaks_file was properly uploaded",
				motifs		=>	$c->model('Available_Motifs')->available_motifs,
			);
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
			`rm $target`;
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
	$c->stash(
		template	=>	'validated_primers.tt',
	);
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
