package FoxPrimer::Model::PrimerDesign::chipPrimerDesign;
use Moose;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Schema;
use FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa;
use FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO;
use FoxPrimer::Model::PrimerDesign::chipPrimerDesign::Primer3;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PrimerDesign::chipPrimerDesign - Catalyst Model

=head1 DESCRIPTION

This is the main sub-controller, which is used by FoxPrimer to design ChIP
primers.

=head1 AUTHOR

Jason R Dobson foxprimer@gmai.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 bed_coordinates

This Moose object holds the coordinates for which the user would like to
design ChIP primers. This is in the form of an Array Ref of Hash Refs.

=cut

has bed_coordinates	=>	(
	is			=>	'ro',
	isa			=>	'ArrayRef[HashRef]',
);

=head2 _chip_genomes_schema

This Moose object contains the Schema for connecting to the ChIP Genomes
FoxPrimer database

=cut

has _chip_genomes_schema	=>	(
	is			=>	'ro',
	isa			=>	'FoxPrimer::Schema',
	default		=>	sub {
		my $self = shift;
		my $dsn = "dbi:SQLite:$FindBin::Bin/../db/chip_genomes.db";
		my $schema = FoxPrimer::Schema->connect($dsn, '', '', '');
		return $schema;
	},
	required	=>	1,
	reader		=>	'chip_genomes_schema',
);

=head2 product_size

This Moose object holds the pre-validated string for the product size.

=cut

has product_size	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 motif

This Moose object holds the pre-validated string for the motif the user
would like to search for in their genomic intervals.

=cut

has motif	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 genome

This Moose object holds the string for the pre-validated genome for ChIP
primer design.

=cut

has genome	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 _mispriming_file

This Moose object is dynamically created based on which species the user
picks on the web form. This object contains the location of the appropriate
mispriming file to be used by Primer3 in scalar string format.

=cut

has _mispriming_file	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	required	=>	1,
	lazy		=>	1,
	default		=>	sub {
		my $self = shift;

		if ($self->species eq 'Human') {
			return "$FindBin::Bin/../root/static/files/human_and_simple";
		} else {
			return "$FindBin::Bin/../root/static/files/rodent_and_simple";
		}
	},
	reader		=>	'mispriming_file'
);

=head2 _genome_id

This Moose object holds the integer value for the genome ID in the
FoxPrimer ChIP genomes database.

=cut

has _genome_id	=>	(
	is			=>	'ro',
	isa			=>	'Int',
	required	=>	1,
	lazy		=>	1,
	default		=>	sub {
		my $self = shift;

		# Fetch the genome ID from the FoxPrimer ChIP database.
		my $search_result =
		$self->chip_genomes_schema->resultset('Genome')->find(
			{
				genome	=>	$self->genome,
			}
		);

		# If a genome was found, return the genome ID, otherwise return an
		# empty string which will cause the Moose constructor to fail.
		if ( $search_result && $search_result->id ) {
			return $search_result->id;
		} else {
			return '';
		}
	},
	reader		=>	'genome_id',
);

=head2 design_primers

This subroutine is the mini-controller, which controls the workflow and
business logic for designing ChIP primers.

=cut

sub design_primers {
	my $self = shift;

	# Pre-declare an Array Ref to hold the designed primers.
	my $designed_primers = [];

	# Pre-declare an Array Ref to hold error messages for primer design
	# errors.
	my $design_errors = [];

	# Iterate through the BED coordinates, and design primers for each
	# set of coordinates.
	foreach my $coordinate_set ( @{$self->bed_coordinates} ) {

		# Run the 'extend_coordinates' subroutine to extend the coordinates
		# based on the product_size string.
		my $extended_coordinate_set = $self->extend_coordinates(
			$coordinate_set
		);

		# Pre-declare an Array Ref to hold the coordinates and FASTA files
		# that will be sent to Primer3 for primer design.
		my $coordinate_sets_for_primer3 = [];

		# Create an instance of
		# FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa and
		# run the create_temp_fasta subroutine to return the location of
		# the temporary FASTA format file for the current coordinates.
		my $twobit_to_fasta =
		FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa->new(
			genome_id		=>	$self->genome_id,
			chromosome		=>	$extended_coordinate_set->{chromosome},
			start			=>	$extended_coordinate_set->{start},
			end				=>	$extended_coordinate_set->{end},
		);
		my $temp_fasta = $twobit_to_fasta->create_temp_fasta;

		# If the user has defined a motif to search for within their
		# sequences create an instance of
		# FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO and run
		# the find_motifs subroutine to return an Array Ref of motif
		# coordinates and an Array Ref of error messages (if any).
		if ( $self->motif && $self->motif ne 'No Motif' ) {

			# Create an instance of
			# FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO and
			# run the 'find_motifs' subroutine to return an Array Ref of
			# Hash Ref coordinates.
			my $run_fimo =
			FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO->new(
				fasta_file	=>	$temp_fasta,
				motif		=>	$self->motif
			);
			my $motif_coordinates = $run_fimo->find_motifs;

			# Remove the temporary FASTA file.
			unlink($temp_fasta);

			# If there were any motifs found, extend the coordinates of
			# these motifs, and create new FASTA format files for each new
			# coordinate set. Otherwise, add an error message to the
			# design_errors Array Ref indicating that the motif could not
			# be found.
			if (@$motif_coordinates) {

				# Iterate through the motif coordinates, run the
				# 'extend_coordinates' subroutine. Then create an instance
				# of
				# FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa
				# to create a new FASTA file for each newly created set of
				# extended coordinates. Add the FASTA file and coordinates
				# to the coordinate_sets_for_primer3 Array Ref.
				foreach my $motif_coordinate_set (@$motif_coordinates) {
					my $extended_motif_coordinates =
					$self->extend_coordinates(
						$motif_coordinate_set
					);

					# Create an instance of
					# FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa
					# and run the 'create_temp_fasta' subroutine to return
					# the path to a new FASTA file.
					my $motif_twobit_to_fa =
					FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa->new(
						genome_id		=>	$self->genome_id,
						chromosome		=>
							$extended_motif_coordinates->{chromosome},

						start			=>
							$extended_motif_coordinates->{start},

						end				=>
							$extended_motif_coordinates->{end}
					);
					$extended_motif_coordinates->{fasta_file} =
					$motif_twobit_to_fa->create_temp_fasta;

					# Add the FASTA file and coordinates to
					# coordinate_sets_for_primer3.
					push(@$coordinate_sets_for_primer3,
						$extended_motif_coordinates
					);
				}
			} else {

				push(@$design_errors,
					'The motif ' . $self->motif . ' was not found by FIMO '
					. 'in the coordinates: ' .
					$extended_coordinate_set->{chromosome} . ':' .
					$extended_coordinate_set->{start} . '-' .
					$extended_coordinate_set->{end}
				);
			}
		} else {

			# Add the extended coordinates and the original FASTA file to
			# the coordinate_sets_for_primer3 Array Ref.
			$extended_coordinate_set->{fasta_file} = $temp_fasta;
			push(@$coordinate_sets_for_primer3, $extended_coordinate_set);
		}

		# Iterate through the coordinate_sets_for_primer3 and create
		# primers and create an instance of
		# FoxPrimer::Model::PrimerDesign::chipPrimerDesign::Primer3 to
		# design primers either within the interval defined by the user or
		# within the user and flanking the target sequence (motif or
		# summit).
		foreach my $coordinate_set_for_primer3
		(@$coordinate_sets_for_primer3) {

			# Create an instance of
			# FoxPrimer::Model::PrimerDesign::chipPrimerDesign::Primer3
			my $primer3 =
			FoxPrimer::Model::PrimerDesign::chipPrimerDesign::Primer3->new(
				fasta_file		=>
					$coordinate_set_for_primer3->{fasta_file},

				genome			=>	$self->genome,
				chromosome		=>
					$coordinate_set_for_primer3->{chromosome},

				start			=>	$coordinate_set_for_primer3->{start},
				end				=>	$coordinate_set_for_primer3->{end},
				target			=>	$coordinate_set_for_primer3->{target},
				product_size	=>	$self->product_size,
				mispriming_file	=>	$self->mispriming_file,
			);

			# Run the 'create_primers' subroutine to return an Array Ref of
			# primers and an error message if Primer3 was unable to design
			# primers.
			my ($chip_primers, $error_message) =
			$primer3->design_primers;

			# If primers were designed, add them to the designed_primers
			# Array Ref.
			if (@$chip_primers) {
				push(@$designed_primers, @$chip_primers);
			} else {
				# If no primers were designed, add the error_message to the
				# design_errors Array Ref.
				push(@$design_errors, $error_message);
			}
		}
	}

	# Run the unique_primers subroutine to return unique primers
	my $unique_primers = $self->unique_primers($designed_primers);

	return ($design_errors, $designed_primers);
}

=head2 extend_coordinates

This subroutine extends the coordinates based on the product_size max
product length.

=cut

sub extend_coordinates {
	my ($self, $coordinates) = @_;

	# Pre-declare a Hash Ref to hold the extended coordinates.
	my $extended_coordinates = {};

	# Extract the min and max product sizes from the product size string.
	my ($min_size, $max_size) = split(/-/, $self->product_size);

	# Calculate the length of the interval.
	my $interval_length = $coordinates->{end} - $coordinates->{start};

	# If the interval length is less than 30 bases, use the original
	# coordinates as required coordinates for Primer3 and extend the
	# coordinates so that they are twice the length of the max product
	# size.
	if  ($interval_length <= 30 ) {

		# Calculate the length to add to each side.
		my $length_to_add = ((2*$max_size) - $interval_length) / 2;

		# Add to the end coordinate, and subtract from the start
		# coordinate to define the extended coordinates. Make sure that
		# the extended coordinates are valid for the current
		# chromosome.
		my $extended_start = $coordinates->{start} - $length_to_add;
		my $extended_end = $coordinates->{end} + $length_to_add;
		if ( $extended_start <= 0 ) {
			$extended_start = 1;
		}
		if ( $extended_end >
			$self->chromosome_sizes->{$coordinates->{chromosome}} ) {
			$extended_end =
			$self->chromosome_sizes->{$coordinates->{chromosome}};
		}

		# Store the coordinates in the Hash Ref.
		$extended_coordinates->{chromosome} = $coordinates->{chromosome};
		$extended_coordinates->{start} = $extended_start;
		$extended_coordinates->{end} = $extended_end;

		# Store a string for Primer3 to know which location to target as
		# the original location.
		$extended_coordinates->{target} = $length_to_add . ',' .
		$interval_length;

	} else {

		# Extend the coordinates equally on each side. First calculate how
		# far to extend the coordinates. The coordinates should be at least
		# twice as long as the max product size. If the coordinates are
		# already longer than the max product size, do not change the
		# length.
		if ( $interval_length >= (2*$max_size) ) {

			# Return the original coordinates.
			$extended_coordinates->{chromosome} =
				$coordinates->{chromosome};

			$extended_coordinates->{start} = $coordinates->{start};
			$extended_coordinates->{end} = $coordinates->{end};
		} else {

			# Calculate the length to add to each side. Rounded down.
			my $length_to_add = int(((2*$max_size) - $interval_length) /
				2);

			# Add to the end coordinate, and subtract from the start
			# coordinate to define the extended coordinates. Make sure that
			# the extended coordinates are valid for the current
			# chromosome.
			my $extended_start = $coordinates->{start} - $length_to_add;
			my $extended_end = $coordinates->{end} + $length_to_add;
			if ( $extended_start <= 0 ) {
				$extended_start = 1;
			}
			if ( $extended_end >
				$self->chromosome_sizes->{$coordinates->{chromosome}} ) {
				$extended_end =
				$self->chromosome_sizes->{$coordinates->{chromosome}};
			}

			# Store the coordinates in the Hash Ref.
			$extended_coordinates->{chromosome} =
				$coordinates->{chromosome};

			$extended_coordinates->{start} = $extended_start;
			$extended_coordinates->{end} = $extended_end;
		}
	}

	return $extended_coordinates;
}

=head2 chromosome_sizes

This subroutine interacts with the FoxPrimer ChIP genomes database to fetch
the path of the chromosome sizes file for the pre-validated user-defined
genome.

=cut

sub chromosome_sizes {
	my $self = shift;

	# Pre-declare a Hash Ref to hold the chromosome sizes information.
	my $chrom_sizes = {};

	# Get the path to the user-defined genome's chromosome sizes file from
	# the FoxPrimer ChIP genomes database.
	my $search_result =
	$self->chip_genomes_schema->resultset('Chromosomesize')->find(
		{
			genome	=>	$self->genome_id,
		}
	);

	# Make sure that a chromosome file path was returned and that the file
	# is readable by FoxPrimer. If not, end execution.
	if ( $search_result && $search_result->path ) {

		# Make sure the file is readable.
		unless ( -r $search_result->path ) {
			die 'The chromosome sizes file ' . $search_result->path .
			' was not readable by FoxPrimer. Please check the file ' .
			'permissions';
		}

		# Open the chromosome sizes file, iterate through the lines and add
		# the information to the chrom_sizes Hash Ref.
		open my $chrom_file, "<", $search_result->path or die
		"Could not read from " . $search_result . "$!\n";
		while(<$chrom_file>) {
			my $line = $_;
			chomp($line);
			my ($chromosome, $length) = split(/\t/, $line);
			$chrom_sizes->{$chromosome} = $length;
		}
		close $chrom_file;
	} else {

		# End execution and return an error message.
		die 'A chromosome sizes file was not found for the genome ' .
		$self->genome . '. Please check that this genome is correctly ' . 
		'installed in the FoxPrimer database.';
	}

	return $chrom_sizes;
}

=head2 unique_primers

This subroutine takes an Array Ref of designed ChIP primers as an argument
and returns only unique primers.

=cut

sub unique_primers {
	my ($self, $all_primers) = @_;

	# Pre-declare an Array Ref to hold the unique primers.
	my $unique_primers = [];

	# Pre-declare a Hash Ref to hold the primers that have been seen.
	my $seen_primers = {};

	# Iterate through the primers, and determine which primers are unique.
	foreach my $primer_set ( @$all_primers ) {

		# Define a string for the primer pair
		my $primer_seqs = join(',',
			$primer_set->{left_primer_sequence},
			$primer_set->{right_primer_sequence}
		);

		# If the primer pair has not been seen before, add it to the
		# unique_primers Array Ref.
		unless ( $seen_primers->{$primer_seqs} ) {
			push(@$unique_primers, $primer_set);

			# Store the primer string in the seen_primers Hash Ref.
			$seen_primers->{$primer_seqs} = 1;
		}
	}

	return $unique_primers;
}

__PACKAGE__->meta->make_immutable;

1;
