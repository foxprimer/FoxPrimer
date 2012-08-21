package FoxPrimer::Model::ChIP_Primer_Design;
use Moose;
use namespace::autoclean;
use FoxPrimer::Model::ChIP_Primer_Design::TwoBitToFa;
use FoxPrimer::Model::ChIP_Primer_Design::Primer3;
use FoxPrimer::Model::Validated_Primer_Entry;
use Data::Dumper;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::ChIP_Primer_Design - Catalyst Model

=head1 DESCRIPTION

This Module takes a set of coordinates from the Catalyst Controller
and uses twoBitToFa from the Kent source tree to create a temporary
Fasta file. The temporary Fasta file is given to Primer3 with relative
locations to design primers (if peaks are summits or motifs).

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 Moose declarations

This section contains the required information to run this module
defined as Moose declarations.

=cut

has chromosome	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has start	=>	(
	is			=>	'rw',
	isa			=>	'Int',
);

has stop	=>	(
	is			=>	'rw',
	isa			=>	'Int',
);

has peak_name	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has product_size	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has genome	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has relative_coordinates_string	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has chromosome_sizes	=>	(
	is			=>	'rw',
	isa			=>	'HashRef',
	default		=>	sub {
		my $self = shift;
		my $genome = $self->genome;
		# Pre-declare a Hash Reference to store the chromosome sizes
		my $chromosome_sizes_hash = {};
		# Open the chromosome sizes file for the specified genome and store the data
		# in the $chromosome_sizes_hash
		my $chromosome_sizes_fh = 'root/static/files/' . $genome . '.chrom.sizes';
		open my $chromosome_sizes_file, "<", $chromosome_sizes_fh or die "Could not read from $chromosome_sizes_fh $!\n";
		while (<$chromosome_sizes_file>) {
			my $line = $_;
			chomp ($line);
			my ($chromosome, $length) = split(/\t/, $line);
			$chromosome_sizes_hash->{$chromosome} = $length;
		}
		return $chromosome_sizes_hash;
	},
	lazy		=>	1,
);

=head2 design_primers

This is the main subroutine called by the Catalyst Controller to design ChIP primers

=cut

sub design_primers {
	my $self = shift;
	# Make a temporary Fasta file based on the desired product size range
	my $twoBitToFa = FoxPrimer::Model::ChIP_Primer_Design::TwoBitToFa->new(
		start			=>	$self->start,
		stop			=>	$self->stop,
		genome			=>	$self->genome,
		chromosome		=>	$self->chromosome,
	);
	$twoBitToFa->create_temp_fasta;
	my $primer3 = FoxPrimer::Model::ChIP_Primer_Design::Primer3->new(
		product_size					=>	$self->product_size,
		relative_coordinates			=>	$self->relative_coordinates_string,
		genomic_dna_start				=>	$self->start,
		genomic_dna_stop				=>	$self->stop,
		genome							=>	$self->genome,
		chromosome						=>	$self->chromosome,
	);
	my $created_chip_primers = $primer3->design_primers;
	return $created_chip_primers;
}

=head2 validate_product_size

This subroutine is called by the Catalyst Controller to determine if the product
size filled by the user are vaild. If there are errors, these are collected in an
Array Ref and returned to the controller. If the product size is valid, it is
returned to the Controller in the form of a string.

=cut

sub validate_product_size {
	my ($self, $parameters) = @_;
	# Pre-declare an Array Ref to hold error messages to be returned to the user
	my $field_errors = [];
	# Remove any whitespace from the Product Size field
	$parameters->{product_size} =~ s/\s//g;
	# Test to ensure that the numbers entered in the Product Size field are valid.
	if ( $parameters->{product_size} =~ /-/ ) {
		my ($lower_limit, $upper_limit) = split(/-/, $parameters->{product_size});
		unless ( ($lower_limit =~ /^\d+$/) && ($upper_limit =~ /^\d+$/) ) {
			push(@$field_errors, "The upper and lower product size limits must both be integers");
		}
		unless ( $upper_limit > $lower_limit ) {
			push(@$field_errors, "The product size upper limit must be larger than the product size lower limit");
		}
	} else {
		push(@$field_errors, "The product size field must be seperated by a '-'");
	}
	return $field_errors;
}

=head2 valid_bed_file

This subroutine is called by the Catalyst Controller to determine if the BED
file uploaded by the user is valid. This subroutine is passed a string of the
file handle, a string of the product size range, and the genome from which the
genomic coordinates are derived.

This subroutine (after checking to make sure the file can be opened, iterates
through the lines of the file and determines if the fields that have been entered
are valid, and then determines whether the coordinates are valid.

If the coordinates are summits, the locations are extended in both directions by
two times the maximum desired product size, as long as these newly calculated coordinates
fall within the allowed coordinates for that organism's chromsome size. This 
function is accomplished by the extend_coordinates function.

=cut

sub valid_bed_file {
	my ($self, $bed_fh) = @_;
	# Pre-declare an Array Ref of errors to be returned to the user
	my $file_errors = [];
	# Pre-declare an Array Ref of Hash Refs to hold the information
	# about valid BED file lines to be returned to the Controller
	my $bed_file_coordinates = [];
	# Open the file, returning an error to the user if the file is not openable
	open my $bed_file, "<", $bed_fh or return ["The file $bed_fh was not able to be read. Please check the permissions on this file"];
	# Initialize a line number, so if there are errors in the file, the user can be referred to the position of the error.
	my $bed_line_number = 1;
	# Pre-declare a hash reference to ensure that the peak names are unique
	my $peaks_names = {};
	my @bed_file_lines = <$bed_file>;
	for (my $i = 0; $i < 20; $i++) {
		my $line = $bed_file_lines[$i];
		chomp($line);
		# Pre-declare a boolean value that will be used to determine if the coordinates of the BED
		# file will be returned to the user
		my $bed_coordinates_boolean = 1;
		my ($chr, $start, $stop, $name) = split(/\t/, $line);
		# Test to ensure that there is a name in the fourth field of the uploaded file.
		unless ( $name ) {
			push (@$file_errors, "The fourth column on line $bed_line_number of your BED file: $bed_fh must have a peak name.");
			$bed_coordinates_boolean = 0;
		}
		# Test to ensure that the fourth field is unique
		if ( $peaks_names->{$name} ) {
			push (@$file_errors, "The fourth column on line $bed_line_number of your BED file: $bed_fh must have a unique peak name.");
			$bed_coordinates_boolean = 0;
		} else {
			$peaks_names->{$name} = 1;
		}
		# Test to ensure that the Chromosome field is valid for this genome
		my $chromosome_length = $self->chromosome_sizes->{$chr};
		unless ( $chromosome_length ) {
			push (@$file_errors, "On line $bed_line_number of your BED file: $bed_fh, the chromosome field: $chr is not valid for the genome: $self->genome.");
			$bed_coordinates_boolean = 0;
		}
		# Test to ensure that the Start field is a positive integer
		unless ( $start =~ /^\d+$/ ) {
			push (@$file_errors, "On line $bed_line_number of your BED file: $bed_fh, the start field: $start is not a positive integer.");
			$bed_coordinates_boolean = 0;
		}
		# Test to ensure that the Start field a valid location on the given chromosome
		unless ( $start < $chromosome_length ) {
			push (@$file_errors, "On line $bed_line_number of your BED file: $bed_fh, the start field: $start is not a valid location for the chromosome: $chr in the genome: $self->genome");
			$bed_coordinates_boolean = 0;
		}
		# Test to ensure that the Stop field is a positive integer
		unless ( $stop =~ /^\d+$/ ) {
			push (@$file_errors, "On line $bed_line_number of your BED file: $bed_fh, the stop field: $stop is not a positive integer.");
			$bed_coordinates_boolean = 0;
		}
		# Test to ensure that the Stop field a valid location on the given chromosome
		unless ( $start <= $chromosome_length ) {
			push (@$file_errors, "On line $bed_line_number of your BED file: $bed_fh, the stop field: $stop is not a valid location for the chromosome: $chr in the genome: $self->genome");
			$bed_coordinates_boolean = 0;
		}
		# Test to ensure that the Stop field is larger than the Start field
		unless ( $stop > $start ) {
			push (@$file_errors, "On line $bed_line_number of your BED file: $bed_fh, the stop field: $stop is not large than the start field: $start.");
			$bed_coordinates_boolean = 0;
		}
		# If the peak type is a summit, use the extend_coordinates subroutine
		# to safely extend the region based on both the desired product size
		# and the limits of the chromosome size
		# Only perform these tasks if all the previously tested fields are valid
		if ( $bed_coordinates_boolean == 1 ) {
			if ( ($start + 1) == $stop ) {
				my ($min_product_size, $max_product_size) = split(/-/, $self->product_size);
				my ($extended_start, $extended_stop, $relative_coordinates_string) = $self->extend_coordinates($chr, $start, $stop, $max_product_size);
				push (@$bed_file_coordinates,
					{
						chromosome					=>	$chr,
						peak_summit_start			=>	$start,
						peak_summit_stop			=>	$stop,
						genomic_dna_start			=>	$extended_start,
						genomic_dna_stop			=>	$extended_stop,
						peak_name					=>	$name,
						relative_coordinates_string	=>	$relative_coordinates_string,
						peak_origin					=>	'summit',
					}
				);
			} elsif ( $stop > ($start + 1) ) {
				push (@$bed_file_coordinates,
					{
						chromosome					=>	$chr,
						genomic_dna_start			=>	$start,
						genomic_dna_stop			=>	$stop,
						peak_name					=>	$name,
						peak_origin					=>	'peak region',
					}
				);
			}
		} 
		$bed_line_number++;
	}
	return ($file_errors, $bed_file_coordinates);
}

=head2 extend_coordinates

This subroutine is passed a chromosome, a start position and a stop position for
either a summit or a motif. Based on both the desired product size and the constraints
of the particular genome and chromosome this subroutine will safely extend the coordinates
and then return these new coordinates a relative coordinates string to be passed to Primer3 
so that the summit or motif will be included in the product.

=cut

sub extend_coordinates {
	my ($self, $chromosome, $start, $stop, $max_product_size) = @_;
	# Determine the size of the chromosome
	my $chromosome_length = $self->chromosome_sizes->{$chromosome};
	# Determine the extension length by multiplying the
	# maximum product size value by two
	my $extension = $max_product_size * 2;
	# Pre-declare varables for the extended start and stop
	my ($extended_start, $extended_stop);
	# Pre-declare a string to hold the relative position string
	my $relative_coordinates_string = '';
	# Determine the extended chromosome positions bounded by
	# valid chromosomal positions
	if ( ($start - $extension) >= 1 ) {
		$extended_start = $start - $extension;
	} else {
		$extended_start = 1;
	}
	if ( ($stop + $extension) <= $chromosome_length ) {
		$extended_stop = $stop + $extension;
	} else {
		$extended_stop = $chromosome_length;
	}
	$relative_coordinates_string = ($start - $extended_start + 1) . ',' .  ($stop - $start + 1);
	return($extended_start, $extended_stop, $relative_coordinates_string);
}

sub define_relative_position {
	my ($self, $created_primers_insert) = @_;
	# Create an instance of Validated_Primer_Entry to use the accessions
	# method which returns a tab-delimited string of the chromosome and
	# the transcriptional start site
	my $promoter_location = FoxPrimer::Model::Validated_Primer_Entry->new(
		genome	=>	$self->genome,
	);
	# Retreive the hash of locations
	my $locations_hash = $promoter_location->gene_bodies;
	# Iterate through each of the created primers
	foreach my $created_primer_insert (@$created_primers_insert) {
		# If relative locations have been defined for this primer pair,
		# iterate through these locations and parse the string
		if ( $created_primer_insert->{relative_locations_raw_strings} ) {
			foreach my $raw_relative_location ( @{$created_primer_insert->{relative_locations_raw_strings}} ) {
				# Pre-declare a string to hold the location string that will be passed back into the hash
				my $final_location_string = '';
				# Extract the accession an general location from each raw relative location
				# Pre-declare an accession and relative region string to hold the parsed strings
				my $accession = '';
				my $relative_region = '';
				if ( $raw_relative_location =~ /^(\w\w_\d+)-Human_(.+)$|^(\w\w_\d+)-Mouse_(.+)$/ ) {
					$accession = $1;
					$relative_region = $2;
				}
				# If the strings have been filled by patter matching, proceed
				if ( $accession && $relative_region ) {
					# Substitute spaces in for underscore charaters in the $relative_region string
					$relative_region =~ s/_/ /g;
					# Extract the Array Ref of position strings from the Gene Body Hash Ref
					my $gene_body_position_strings = $locations_hash->{$accession};
					# Iterate through the position strings and extracting the positions
					foreach my $gene_body_position_string (@$gene_body_position_strings) {
						my ($chromosome, $start, $stop, $strand) = split(/\t/, $gene_body_position_string);
						# Only proceed if the mapping for this transcript is on the same chromosome
						# as the primer pair
						if ($chromosome eq $created_primer_insert->{chromosome}) {
							# Unless the primer pair is within 100Kb of the gene body, do not calculate the
							# relative position
							if (( abs($created_primer_insert->{left_primer_five_prime} - $start )) <= 100000 ||  # Left primer is within 100Kb of gene body
								( abs($created_primer_insert->{right_primer_five_prime} - $start )) <= 100000 || # Right primer is within 100Kb of gene body
								( abs($created_primer_insert->{left_primer_five_prime} - $stop )) <= 100000 ||   # Left primer is within 100Kb of gene body
								( abs($created_primer_insert->{right_primer_five_prime} - $stop )) <= 100000 ||  # Right primer is within 100Kb of gene body
								( ( $created_primer_insert->{left_primer_five_prime} >= $start &&
								    $created_primer_insert->{left_primer_five_prime} <= $stop ) ||               # Left primer is inside the gene body
								  ( $created_primer_insert->{left_primer_five_prime} >= $stop &&
								    $created_primer_insert->{left_primer_five_prime} <= $start ) ) ||
								( ( $created_primer_insert->{right_primer_five_prime} >= $start &&
								    $created_primer_insert->{right_primer_five_prime} <= $stop ) ||               # Right primer is inside the gene body
								  ( $created_primer_insert->{right_primer_five_prime} >= $stop &&
								    $created_primer_insert->{right_primer_five_prime} <= $start ) )             ) {
								# The strand the gene body is on will determine how the math is done to calculate
								# the difference in bases between the transcriptional start site and the primer
								# pair positions
								# Pre-declare a scalar to hold the relative position values
								my ($left_primer_relative_position, $right_primer_relative_position);
								if ( $strand eq '+') {
									# Relative positions are calculated by subtracting the start position of the
									# gene body from the 5'-position of the primers
									$left_primer_relative_position = $created_primer_insert->{left_primer_five_prime} - $start;
									$right_primer_relative_position = $created_primer_insert->{right_primer_five_prime} - $start;
								} elsif ( $strand eq '-' ) {
									# Relative positions are calculated by subtracting the the 5'positions of the primers
									# from the gene body stop site
									$left_primer_relative_position = $stop - $created_primer_insert->{left_primer_five_prime};
									$right_primer_relative_position = $stop - $created_primer_insert->{right_primer_five_prime};
								} else {
									die "There is a fatal problem with the Gene Body file in your installation. Please check the manual for definitions as to how these files should be structured and named\n";
								}
								# If the relative primer positions are positive values, append a '+' to the beginning of the string
								if ( $left_primer_relative_position > 0 ) {
									$left_primer_relative_position = '+' . $left_primer_relative_position;
								}
								if ( $right_primer_relative_position > 0 ) {
									$right_primer_relative_position = '+' . $right_primer_relative_position;
								}
								# Create a final location string and add it to the relative_locations Array Ref in the created_primers_insert
								# Hash Ref
								push (@{$created_primer_insert->{relative_locations}}, $relative_region . ' of ' . $accession . " ($left_primer_relative_position to $right_primer_relative_position)");
							}
						}
					}
				} else {
					die "There was a fatal error determining the accession and relative region. Please contact the system administrator\n";
				}
			}
		}
	}
	return $created_primers_insert;
}

__PACKAGE__->meta->make_immutable;

1;
