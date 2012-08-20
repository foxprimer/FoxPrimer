package FoxPrimer::Model::ChIP_Primer_Design::Primer3;
use Moose;
use namespace::autoclean;
use FoxPrimer::Model::Updated_Primer3_Run;
use Bio::SeqIO;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::ChIP_Primer_Design::Primer3 - Catalyst Model

=head1 DESCRIPTION

This Catalyst Model is designed to create ChIP primers using
Primer3.

Primers sequences, information and positions are returned by
the main subroutine.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 Moose declarations

This section contains Moose object-oriented constructor declarations

=cut

has genome	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has product_size	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has relative_coordinates_string	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has genomic_dna_start		=>	(
	is			=>	'rw',
	isa			=>	'Int',
);

has genomic_dna_stop		=>	(
	is			=>	'rw',
	isa			=>	'Int',
);

has chromosome		=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has mispriming_file	=>	(
	is			=>	'rw',
	isa			=>	'Str',
	default		=>	sub {
		my $self = shift;
		# Pre-declare a string to hold the path to the species-appropriate mispriming file
		my $misprime_fh;
		my $genome = $self->genome;
		if ( $genome eq 'hg19' ) {
			$misprime_fh = 'root/static/files/human_and_simple';
		} else {
			$misprime_fh = 'root/static/files/rodent_and_simple';
		}
		return $misprime_fh;
	},
	required	=>	1,
	lazy		=>	1,
);

has primer3_executable	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	default		=>	sub {
		my $self = shift;
		my $primer3_path = `which primer3_core`;
		chomp ($primer3_path);
		return $primer3_path;
	},
	required	=>	1,
);

=head2 design_primers

This is the main subroutine, which when given a set of coordinates and
the type of primer to be designed, will make a call to Primer3 and then
returns an Array Ref of designed primers

=cut

sub design_primers {
	my $self = shift; 
	# Extract the sequence from the temporary Fasta file use Bio::SeqIO
	my $seqio = Bio::SeqIO->new(
		-file		=>	'tmp/fasta/temp.fa',
	);
	my $seq = $seqio->next_seq;
	# Create and run and instance of Primer3
	my $primer3 = FoxPrimer::Model::Updated_Primer3_Run->new(
		-seq		=>	$seq,
		-outfile	=>	'temp.out',
		-path		=>	$self->primer3_executable,
	);
	if ( $self->relative_coordinates_string ) {
		# Create a string for the relative coordiantes to be passed to Primer3
		$primer3->add_targets(
			'PRIMER_MISPRIMING_LIBRARY'		=>	$self->mispriming_file,
			'PRIMER_NUM_RETURN'				=>	5,
			'PRIMER_PRODUCT_SIZE_RANGE'		=>	$self->product_size,
			'SEQUENCE_TARGET'				=>	$self->relative_coordinates_string,
		);
	} else {
		$primer3->add_targets(
			'PRIMER_MISPRIMING_LIBRARY'		=>	$self->mispriming_file,
			'PRIMER_NUM_RETURN'				=>	5,
			'PRIMER_PRODUCT_SIZE_RANGE'		=>	$self->product_size,
		);
	}
	my $results = $primer3->run;
	# Create a Hash Ref to hold the primer information to return to the Catalyst Controller
	my $created_chip_primers = {};
	# Create a boolean value to send back to the Catalyst Controller if no primers we able
	# to be designed
	if ( $results->number_of_results > 0) {
		# Iterate through the primer results. Mapping their location back to full genomic coordinates.
		for ( my $i = 0; $i < $results->number_of_results; $i++ ) {
			my $temp_result = $results->primer_results($i);
			my ($left_primer_temp_start, $right_primer_temp_start);
			($left_primer_temp_start, $created_chip_primers->{'Primer Pair ' . $i}{left_primer_length}) = split(/,/, $temp_result->{PRIMER_LEFT});
			($right_primer_temp_start, $created_chip_primers->{'Primer Pair ' . $i}{right_primer_length}) = split(/,/, $temp_result->{PRIMER_RIGHT});
			$created_chip_primers->{'Primer Pair ' . $i}{left_primer_5prime} = $self->genomic_dna_start + ($left_primer_temp_start - 1);
			$created_chip_primers->{'Primer Pair ' . $i}{left_primer_3prime} = $created_chip_primers->{'Primer Pair ' . $i}{left_primer_5prime} + $created_chip_primers->{'Primer Pair ' . $i}{left_primer_length};
			$created_chip_primers->{'Primer Pair ' . $i}{right_primer_5prime} = $self->genomic_dna_start + ($right_primer_temp_start - 1);
			$created_chip_primers->{'Primer Pair ' . $i}{right_primer_3prime} = $created_chip_primers->{'Primer Pair ' . $i}{right_primer_5prime} - $created_chip_primers->{'Primer Pair ' . $i}{left_primer_length};
			$created_chip_primers->{'Primer Pair ' . $i}{left_primer_sequence} = $temp_result->{PRIMER_LEFT_SEQUENCE};
			$created_chip_primers->{'Primer Pair ' . $i}{right_primer_sequence} = $temp_result->{PRIMER_RIGHT_SEQUENCE};
			$created_chip_primers->{'Primer Pair ' . $i}{left_primer_tm} = $temp_result->{PRIMER_LEFT_TM};
			$created_chip_primers->{'Primer Pair ' . $i}{right_primer_tm} = $temp_result->{PRIMER_RIGHT_TM};
			$created_chip_primers->{'Primer Pair ' . $i}{product_size} = $temp_result->{PRIMER_PAIR_PRODUCT_SIZE};
			$created_chip_primers->{'Primer Pair ' . $i}{product_penalty} = $temp_result->{PRIMER_PAIR_PENALTY};
			$created_chip_primers->{'Primer Pair ' . $i}{chromosome} = $self->chromosome;
		}
	}
	# Clean up the temporary files
	`rm tmp/fasta/temp.fa`;
	`rm temp.out`;
	return $created_chip_primers;
}

__PACKAGE__->meta->make_immutable;

1;
