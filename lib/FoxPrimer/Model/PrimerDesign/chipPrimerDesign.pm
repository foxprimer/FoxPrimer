package FoxPrimer::Model::PrimerDesign::chipPrimerDesign;
use Moose;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Schema;
use FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa;

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

	# Iterate through the BED coordinates, and design primers for each
	# set of coordinates.
	foreach my $coordinate_set ( @{$self->bed_coordinates} ) {

		# Run the 'extend_coordinates' subroutine to extend the coordinates
		# based on the product_size string.
		my $extended_coordinate_set = $self->extend_coordinates(
			$coordinate_set
		);

		# Pre-declare an Array Ref to hold the FASTA files that will be
		# given to Primer3 for primer design.
		my $fasta_files = [];

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
			# FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO.
		} else {

			# Add the original FASTA file to the fasta_files Array Ref.
			push(@$fasta_files, $temp_fasta);
		}
	}

	return $designed_primers;
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

__PACKAGE__->meta->make_immutable;

1;
