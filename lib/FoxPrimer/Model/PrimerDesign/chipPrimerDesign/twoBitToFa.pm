package FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa;
use Moose;
use namespace::autoclean;
use FindBin;
use File::Which;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa - Catalyst Model

=head1 DESCRIPTION

This module takes writes the FASTA-format sequence of the user-defined
coordinates to a temporary file.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 genome_id

This Moose object holds the integer for the user-defined genome ID.

=cut

has genome_id	=>	(
	is			=>	'ro',
	isa			=>	'Int',
);

=head2 chromosome

This Moose object holds the string for the user-defined pre-validated
chromosome.

=cut

has chromosome	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 start

This Moose object holds the integer value for the user-defined
pre-validated chromosome start position.

=cut

has start	=>	(
	is			=>	'ro',
	isa			=>	'Int',
);

=head2 end

This Moose object holds the integer value for the user-defined
pre-validated chromosome end position.

=cut

has end	=>	(
	is			=>	'ro',
	isa			=>	'Int',
);

=head2 _twobit_executable

This Moose object contains the path to the Kent utility twoBitToFa.

=cut

has _twobit_executable	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	required	=>	1,
	lazy		=>	1,
	default		=>	sub {
		my $self = shift;
		my $twobit_path = which('twoBitToFa');
		chomp($twobit_path);
		return $twobit_path;
	},
	reader		=>	'twobit_executable',
);

=head2 _chip_genomes_schema

This Moose object holds the DBIx::Class::Schema object to interact with the
FoxPrimer ChIP database.

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

=head2 _twobit_file

This Moose object holds the string for the path to the 2bit file of the
user-defined genome.

=cut

has _twobit_file	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	required	=>	1,
	lazy		=>	1,
	default		=>	sub {
		my $self = shift;
		my $search_result =
		$self->chip_genomes_schema->resultset('Twobit')->find(
			{
				genome	=>	$self->genome_id,
			}
		);
		return $search_result->path;
	},
	reader		=>	'twobit_file',
);

=head2 create_temp_fasta

This subroutine takes the user-defined coordinates and writes the sequence
at these coordinates to a temporary file in FASTA format using twoBitToFa.
The path to the temporary file is returned.

=cut

sub create_temp_fasta {
	my $self = shift;

	# Store the 2bit file in a local string.
	my $two_bit_file = $self->twobit_file;

	# Create a string for the location of the temporary FASTA-format file
	# that will be written.
	my $temp_fasta = "$FindBin::Bin/../tmp/fasta/" . $self->chromosome .
	':' . $self->start . '-' . $self->end . '.fa';

	# Define a string for the call to twoBitToFa
	my $twobit_call = $self->twobit_executable . ' ' . $two_bit_file . ':'
	. $self->chromosome . ':' . $self->start . '-' . $self->end . ' ' .
	$temp_fasta;

	# Execute the call.
	`$twobit_call`;

	# Make sure that the file has been created and is readable by
	# FoxPrimer.
	if ( -r $temp_fasta ) {
		return $temp_fasta;
	} else {

		# Cease execution.
		die 'Unable to write to the file: ' . $temp_fasta . '.' .
		' Please check your installation of FoxPrimer.';
	}
}

__PACKAGE__->meta->make_immutable;

1;
