package FoxPrimer::Model::PrimerDesign::chipPrimerDesign::Primer3;
use Moose;
use namespace::autoclean;
use File::Which;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Model::Updated_Primer3_Run;
use Bio::SeqIO;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PrimerDesign::chipPrimerDesign::Primer3 - Catalyst Model

=head1 DESCRIPTION

This Module designs primer for ChIP-qPCR.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 fasta_file

This Moose object holds the path to the FASTA file of sequence for primer
design.

=cut

has fasta_file	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 genome

This Moose object holds the pre-validated string for the genome to which
the primers are designed.

=cut

has	genome	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 chromosome

This Moose object holds the string for the chromosome on which these
primers are being designed.

=cut

has chromosome	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 start

This Moose object holds the integer value for the genomic start coordinate.

=cut

has start	=>	(
	is			=>	'ro',
	isa			=>	'Int'
);

=head2 end

This Moose object holds the integer value for the genome end coordinate.

=cut

has end	=>	(
	is			=>	'ro',
	isa			=>	'Int',
);

=head2 target

This Moose object holds the string that will be passed to Primer3 for the
target coordinates around which primers must be designed.

=cut

has target	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	default		=>	'None',
);

=head2 product_size

This Moose object holds the pre-validated product size string to be passed
to Primer3.

=cut

has product_size	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 mispriming_file

This Moose object holds the path to the mispriming file that Primer3 will
use to design primers.

=cut

has mispriming_file	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 _primer3_executable

This Moose object dynamically locates the path to the primer3 executable
'primer3_core'. If primer3_core can not be found, the program will die
horribly.

=cut

has _primer3_executable	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	required	=>	1,
	lazy		=>	1,
	default		=>	sub {
		my $self = shift;
		my $primer3_executable = which('primer3_core');
		chomp($primer3_executable);
		return $primer3_executable;
	},
	reader		=>	'primer3_executable'
);

=head2 create_primers

This subroutine will make a call to Primer3 and design primers and return
an Array Ref of Hash Refs of primer information.

=cut

sub create_primers {
	my $self = shift;

	# Pre-declare a Array Ref to hold the primers created.
	my $created_primers = [];

	# Pre-declare a String to hold any error messages.
	my $error_messages = '';

	# Extract the cDNA sequence by running the 'cdna_sequence' subroutine
	my $cdna_seq = $self->cdna_sequence;

	# Create a FoxPrimer::Model::Updated_Primer3_Run object
	my $primer3 = FoxPrimer::Model::Updated_Primer3_Run->new(
		-seq		=>	$cdna_seq,
		-outfile	=>	"$FindBin::Bin/../tmp/primer3/temp.out",
		-path		=>	$self->primer3_path
	);

	# Check to see if a target has been defined to Primer3 to design
	# primers around. If one has add it to Primer3.
	if ( $self->target ne 'None' ) {
		# Create a string for the relative coordiantes to be passed to Primer3
		$primer3->add_targets(
			'PRIMER_MISPRIMING_LIBRARY'		=>	$self->mispriming_file,
			'PRIMER_NUM_RETURN'				=>	5,
			'PRIMER_PRODUCT_SIZE_RANGE'		=>	$self->product_size,
			'SEQUENCE_TARGET'				=>	$self->target,
		);
	} else {
		$primer3->add_targets(
			'PRIMER_MISPRIMING_LIBRARY'		=>	$self->mispriming_file,
			'PRIMER_NUM_RETURN'				=>	5,
			'PRIMER_PRODUCT_SIZE_RANGE'		=>	$self->product_size,
		);
	}

	# Run primer3 and return the results as a Hash Ref
	my $results = $primer3->run;

	# Make sure that primer3 was able to create primers under the
	# conditions specified by the user. If not return an error message.
	if ( $results->number_of_results > 0 ) {

		# Iterate through the primer results. Mapping their location back
		# to full genomic coordinates.
		for ( my $i = 0; $i < $results->number_of_results; $i++ ) {
			
			# Store the primer results in a local Hash Ref.
			my $primer_result = $results->primer_results($i);

			# Pre-declare a local Hash Ref for the primer information.
			my $primer_info = {};

			# Pre-declare scalar variables for the relative start positions
			# of the left and right primers.
			my ($left_primer_temp_start, $right_primer_temp_start);

			# Split the left and right primer coordinates strings, storing
			# the relative start positions in the local variables, and the
			# lengths in the created_primers Hash Ref.
			($left_primer_temp_start, $primer_info->{left_primer_length}) =
			split(/,/, $primer_result->{PRIMER_LEFT});
			($right_primer_temp_start, $primer_info->{right_primer_length})
			= split(/,/, $primer_result->{PRIMER_RIGHT});

			# Calculate and store the 5'- and 3'-positions of the left and
			# right primers.
			$primer_info->{left_primer_5prime} =
			$self->start + ($left_primer_temp_start - 1);

			$primer_info->{left_primer_3prime} =
			$primer_info->{left_primer_5prime} +
			$primer_info->{left_primer_length};

			$primer_info->{right_primer_5prime} =
			$self->start + ($right_primer_temp_start - 1);

			$primer_info->{right_primer_3prime} =
			$primer_info->{right_primer_5prime} -
			$primer_info->{left_primer_length};

			# Store the primer sequences
			$primer_info->{left_primer_sequence} =
			$primer_result->{PRIMER_LEFT_SEQUENCE};
			$primer_info->{right_primer_sequence}
			= $primer_result->{PRIMER_RIGHT_SEQUENCE};

			# Store the primer Tms
			$primer_info->{left_primer_tm} =
			$primer_result->{PRIMER_LEFT_TM};
			$primer_info->{right_primer_tm} =
			$primer_result->{PRIMER_RIGHT_TM};

			# Store the product size, product penalty, chromosome and
			# genome
			$primer_info->{product_size} =
			$primer_result->{PRIMER_PAIR_PRODUCT_SIZE};
			$primer_info->{product_penalty} =
			$primer_result->{PRIMER_PAIR_PENALTY};
			$primer_info->{chromosome} = $self->chromosome;
			$primer_info->{genome} = $self->genome;

			# Add the primer_info Hash Ref to the created_primers Array
			# Ref.
			push(@$created_primers, $primer_info);
		}

		return ($created_primers, $error_messages);
	} else {

		$error_messages = "Primer3 was unable to design primers for " . 
		"the sequence: " . $self->chromosome . ':' . $self->start . '-' .
		$self->end . " under the conditions you have specified.";

		return ($created_primers, $error_messages);
	}
}

=head2 cdna_sequence

This subroutine takes the user-defined path to the cDNA sequence in FASTA
format and extracts the sequence using Bio::SeqIO.

=cut

sub cdna_sequence {
	my $self = shift;

	# Create a Bio::SeqIO object for the cDNA file provided by the user.
	my $seqio = Bio::SeqIO->new(
		-file	=>	$self->cdna_fh,
		-format	=>	'FASTA'
	);

	# Extract the sequence from the file and return it
	return $seqio->next_seq;
}

__PACKAGE__->meta->make_immutable;

1;
