package FoxPrimer::Model::ChIP_Primer_Design;
use Moose;
use namespace::autoclean;
use FoxPrimer::Model::Updated_Primer3_Run;
use Bio::SeqIO;

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

has primer_type	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

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

has twoBitToFa_executable	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	default		=>	sub {
		my $self = shift;
		my $twoBit_path = `which twoBitToFa`;
		chomp ($twoBit_path);
		return $twoBit_path;
	},
	required	=>	1,
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

=head2 design_primers

This is the main subroutine called by the Catalyst Controller to design ChIP primers

=cut

sub design_primers {
	my $self = shift;
	# Make a temporary Fasta file based on the desired product size range
	my ($relative_coordinates_bool, $relative_coordinates, $genomic_dna_start, $genomic_dna_stop) = $self->_create_temp_fasta;
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
	if ( $relative_coordinates_bool == 1 ) {
		# Create a string for the relative coordiantes to be passed to Primer3
		my $relative_coordinates_string = $relative_coordinates->{start} . ',' . ($relative_coordinates->{stop} - $relative_coordinates->{start});
		$primer3->add_targets(
			'PRIMER_MISPRIMING_LIBRARY'		=>	$self->mispriming_file,
			'PRIMER_NUM_RETURN'				=>	5,
			'PRIMER_PRODUCT_SIZE_RANGE'		=>	$self->product_size,
			'SEQUENCE_TARGET'				=>	$relative_coordinates_string,
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
	my $unable_to_make_primers = 0;
	if ( ! $results->number_of_results ) {
		$unable_to_make_primers = 1;
	} else {
		# Iterate through the primer results. Mapping their location back to full genomic coordinates.
		for ( my $i = 0; $i < $results->number_of_results; $i++ ) {
			my $temp_result = $results->primer_results($i);
			my ($left_primer_temp_start, $right_primer_temp_start);
			($left_primer_temp_start, $created_chip_primers->{'Primer Pair ' . $i}{left_primer_length}) = split(/,/, $temp_result->{PRIMER_LEFT});
			($right_primer_temp_start, $created_chip_primers->{'Primer Pair ' . $i}{right_primer_length}) = split(/,/, $temp_result->{PRIMER_RIGHT});
			$created_chip_primers->{'Primer Pair ' . $i}{left_primer_5prime} = $genomic_dna_start + ($left_primer_temp_start - 1);
			$created_chip_primers->{'Primer Pair ' . $i}{left_primer_3prime} = $created_chip_primers->{'Primer Pair ' . $i}{left_primer_5prime} + $created_chip_primers->{'Primer Pair ' . $i}{left_primer_length};
			$created_chip_primers->{'Primer Pair ' . $i}{right_primer_5prime} = $genomic_dna_start + ($right_primer_temp_start - 1);
			$created_chip_primers->{'Primer Pair ' . $i}{right_primer_3prime} = $created_chip_primers->{'Primer Pair ' . $i}{right_primer_5prime} - $created_chip_primers->{'Primer Pair ' . $i}{left_primer_length};
			$created_chip_primers->{'Primer Pair ' . $i}{left_primer_sequence} = $temp_result->{PRIMER_LEFT_SEQUENCE};
			$created_chip_primers->{'Primer Pair ' . $i}{right_primer_sequence} = $temp_result->{PRIMER_RIGHT_SEQUENCE};
			$created_chip_primers->{'Primer Pair ' . $i}{left_primer_tm} = $temp_result->{PRIMER_LEFT_TM};
			$created_chip_primers->{'Primer Pair ' . $i}{right_primer_tm} = $temp_result->{PRIMER_RIGHT_TM};
			$created_chip_primers->{'Primer Pair ' . $i}{product_size} = $temp_result->{PRIMER_PAIR_PRODUCT_SIZE};
			$created_chip_primers->{'Primer Pair ' . $i}{product_penalty} = $temp_result->{PRIMER_PAIR_PENALTY};
		}
	}
	# Clean up the temporary files
	`rm tmp/fasta/temp.fa`;
	`rm temp.out`;
	return ($unable_to_make_primers, $created_chip_primers);
}

=head2 _create_temp_fasta

This is a private subroutine that creates a temporary Fasta file based on the desired
product size. This subroutine then determines whether relative locations need to be
returned if the primer design type is either for a motif or a summit.

=cut

sub _create_temp_fasta {
	my $self = shift;
	# Predeclare a boolean variable to determine whether relative coordinates
	# need to be determined and returned
	my $relative_coordiantes_bool = 0;
	if ( $self->primer_type eq 'motif' || $self->primer_type eq 'summit' ) {
		$relative_coordiantes_bool = 1;
	}
	my $genomic_dna_start = $self->start;
	my $genomic_dna_stop = $self->stop;
	# Split the min and max product 
	my ($min_product, $max_product) = split(/-/, $self->product_size);
	# Pre-declare a Hash Ref to hold the relative coordiantes of the motif or summit
	my $relative_coordinates = {};
	# If the region given is a motif or summit, extend the genomic_dna_start
	# and genomic_dna_stop by two times the max_product as long as these
	# coordinates are allowed by the chromosome sizes
	if ( $relative_coordiantes_bool == 1 ) {
		my $chromosome_length = $self->chromosome_sizes->{$self->chromosome};
		my $extension = 2 * $max_product;
		if (($genomic_dna_start - $extension) >= 1 ) { 
			$relative_coordinates->{start} = 1 + $extension;
			$relative_coordinates->{stop} = $relative_coordinates->{start} + ($genomic_dna_stop - $genomic_dna_start);
			$genomic_dna_start -= $extension; 
		} else { 
			$genomic_dna_start = 1;
			$relative_coordinates->{start} = $genomic_dna_start;
			$relative_coordinates->{stop} = $relative_coordinates->{start} + ($genomic_dna_stop - $genomic_dna_start);
		}
		if (($genomic_dna_stop + $extension) <= $chromosome_length) {
			$genomic_dna_stop += $extension;
		} else {
			$genomic_dna_stop = $chromosome_length;
		}
	}
	# Get the twoBitToFa executable and create the temporary Fasta file
	my $twoBitToFa_executable = $self->twoBitToFa_executable;
	my $genome = 'root/static/files/' . $self->genome . '.2bit';
	my $out_file = 'tmp/fasta/temp.fa';
	my $call_string = $genome . ':' . $self->chromosome . ':' . $genomic_dna_start . '-' . $genomic_dna_stop;
	`$twoBitToFa_executable $call_string $out_file`;
	return ($relative_coordiantes_bool, $relative_coordinates, $genomic_dna_start, $genomic_dna_stop);
}

__PACKAGE__->meta->make_immutable;

1;
