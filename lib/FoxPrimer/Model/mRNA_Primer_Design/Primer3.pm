package FoxPrimer::Model::mRNA_Primer_Design::Primer3;
use Moose;
use namespace::autoclean;
use Bio::Tools::Primer3;
use Bio::SeqIO;
use FoxPrimer::Model::Updated_Primer3_Run;
use Data::Dumper;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::mRNA_Primer_Design::Primer3 - Catalyst Model

=head1 DESCRIPTION

This module is used to design qPCR primers for cDNA sequences.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 Moose declarations

This section has the declarations for items that can be added to the object
upon creation.

=cut


has product_size	=>	(
	is		=>	'rw',
	isa		=>	'Str',
);

has mispriming_file	=>	(
	is			=>	'rw',
	isa			=>	'Str',
	default		=>	sub { die "You must create this object with a mispriming file\n"; },
	required	=>	1,
	lazy		=>	1,
);

has primer3_path	=>	(
	is			=>	'rw',
	isa			=>	'Str',
	default		=>	sub { die "You must create this object with the path to the primer3_core executable\n"; },
	required	=>	1,
	lazy		=>	1,
);

=head2 create_primers

This subroutine is called by the Catalyst Model mRNA_Primer_Design.
For each mRNA to make, this subroutine uses Primer3 to make several
hundred primers based on the defined product size. Then, the coordinates
of each primer pair are calculated and stored in the structure and returned
to the mRNA_Primer_Design Module.

=cut

sub create_primers {
	my ($self, $structure) = @_;
	# Pre-declare an Array Ref to hold error messages for any mRNAs for which
	# Primer3 is unable to make primers using the default settings.
	my $error_messages = [];
	# Pre-declare a new structure that will store the same information as the
	# structure given to this subroutine, only this structure will only store
	# information for mRNAs for which Primer3 was able to design primers.
	my $created_primers = [];
	# Iterate through the mRNAs in the structure, making primers for each mRNA
	# with Primer3, defining the relative coordinates of these primers and then
	# storing the information in the structure
	foreach my $mrna ( @$structure ) {
		# Create a new Bio::SeqIO object with the file handle for the cDNA Fasta
		# sequence
		my $seqio = Bio::SeqIO->new(
			-file	=>	$mrna->{rna_fh},
		);
		# Extract the sequence from the Bio::SeqIO object
		my $cdna_seq = $seqio->next_seq;
		# Create a Primer3 object
		my $primer3 = FoxPrimer::Model::Updated_Primer3_Run->new(
			-seq		=>	$cdna_seq,
			-outfile	=>	'tmp/primer3/temp.out',
			-path		=>	$self->primer3_path,
		);
		# Ensure that primer3_core is executable
		unless ($primer3->executable) {
			die "The file $self->primer3_path is not executable. Please check your installation or permissions.";
		}
		# Add the mispriming library, number to make, and product size range to the primer3 object
		$primer3->add_targets(
			'PRIMER_MISPRIMING_LIBRARY'		=>	$self->mispriming_file,
			'PRIMER_NUM_RETURN'				=>	500,
			'PRIMER_PRODUCT_SIZE_RANGE'		=>	$self->product_size,
		);
		# Run primer3 to create primers
		my $results = $primer3->run;
		# Ensure that primers have been designed. If no primers have been designed, add an error
		# string to the error message return
		if ( $results->number_of_results > 0 ) {
			$mrna->{'Number of Primers'} = $results->number_of_results;
			# Iterate through the primers that have been designed and extract their coordinates
			for (my $i = 0; $i < $mrna->{'Number of Primers'}; $i++) {
				my $temp_result = $results->primer_results($i);
				$mrna->{designed_primers}{'Primer Pair ' . $i}{'Left Primer Coordinates'} = $temp_result->{PRIMER_LEFT};
				$mrna->{designed_primers}{'Primer Pair ' . $i}{'Right Primer Coordinates'} = $temp_result->{PRIMER_RIGHT};
				$mrna->{designed_primers}{'Primer Pair ' . $i}{'Left Primer Sequence'} = $temp_result->{PRIMER_LEFT_SEQUENCE};
				$mrna->{designed_primers}{'Primer Pair ' . $i}{'Right Primer Sequence'} = $temp_result->{PRIMER_RIGHT_SEQUENCE};
				$mrna->{designed_primers}{'Primer Pair ' . $i}{'Left Primer Tm'} = $temp_result->{PRIMER_LEFT_TM};
				$mrna->{designed_primers}{'Primer Pair ' . $i}{'Right Primer Tm'} = $temp_result->{PRIMER_RIGHT_TM};
				$mrna->{designed_primers}{'Primer Pair ' . $i}{'Product Size'} = $temp_result->{PRIMER_PAIR_PRODUCT_SIZE};
				$mrna->{designed_primers}{'Primer Pair ' . $i}{'Product Penalty'} = $temp_result->{PRIMER_PAIR_PENALTY};
			}
			push (@$created_primers, $mrna);
		} else {
			push (@$error_messages, "Primer3 was not able to make primers for the mRNA accession: $mrna->{mrna} using the default settings.");
		}
	}
	return ($error_messages, $created_primers);
}

__PACKAGE__->meta->make_immutable;

1;
