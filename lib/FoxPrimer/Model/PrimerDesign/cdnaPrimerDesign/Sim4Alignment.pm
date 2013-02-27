package FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment;
use Moose;
use namespace::autoclean;
use FindBin;
use Bio::Tools::Run::Alignment::Sim4;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment - Catalyst Model

=head1 DESCRIPTION

This module uses the BioPerl module for running Sim4 to align a cDNA
sequence to a genomic DNA sequence and then parses the resultant
coordinates.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 cdna_fh

This Moose object holds the string for the location of the cDNA FASTA
format sequence file.

=cut

has cdna_fh	=>	(
	is		=>	'ro',
	isa		=>	'Str'
);

=head2 genomic_dna_fh

This Moose object holds the string for the location of the genomic DNA
FASTA format sequence file.

=cut

has genomic_dna_fh	=>	(
	is		=>	'ro',
	isa		=>	'Str'
);

=head2 sim4_alignment

This subroutine is the main subroutine which creates s
Bio::Tools::Run::Alignment::Sim4 object with the supplied files. Then this
subroutine parses the results returned from Sim4 into a Hash Ref and
returns these coordinates.

=cut

sub sim4_alignment {
	my $self = shift;

	# Create a Bio::Tools::Run::Alignment::Sim4 object
	my $sim4 = Bio::Tools::Run::Alignment::Sim4->new(
		cdna_seq		=>	$self->cdna_fh,
		genomic_seq		=>	$self->genomic_dna_fh,
	);

	# Run Sim4, which returns the possible alignments in an Array
	my @exon_sets = $sim4->align;

	# Pre-declare a Hash Ref to hold the coordinates found in the
	# alignments from Sim4.
	my $coordinates = {};

	# Define an integer for the number of alignments found by Sim4
	my $alignment_iterator = 0;

	# Iterate through the alignments found by Sim4. Parsing the coordinates
	# into the coordinates Hash Ref.
	foreach my $set (@exon_sets) {

		# Increase the alignment iterator
		$alignment_iterator++;

		# Define an integer to use for iteration through the number of
		# exons found by Sim4.
		my $exon_iterator = 0;

		# Iterate through the exons defined by Sim4.
		foreach my $exon ( $set->sub_SeqFeature ) {

			# Increase the exon iterator
			$exon_iterator++;

			# Store the genomic DNA start position for this exon and
			# alignment,
			$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' .
				$exon_iterator}{'Genomic'}{'Start'} = $exon->start;

			# Store the genomic DNA stop position for this exon and
			# alignment.
			$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' .
				$exon_iterator}{'Genomic'}{'End'} = $exon->end;

			# Store the cDNA start position for this exon and alignment
			$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' .
				$exon_iterator}{'mRNA'}{'Start'} = $exon->est_hit->start;

			# Store the cDNA stop position for this exon and alignment
			$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' .
				$exon_iterator}{'mRNA'}{'Stop'} = $exon->est_hit->end;
		}

		# Store the number of exons in the coordinates Hash Ref.
		$coordinates->{'Alignment ' . $alignment_iterator}{
		'Number of Exons'} = $exon_iterator;

		# Calculate the number of sizes of the introns defined for the
		# current alignment by Sim4
		for ( my $intron_iterator = 1; $intron_iterator <
			($exon_iterator-1); $intron_iterator++ ) {

			# Store the size of the intron in the coordinates Hash Ref.
			$coordinates->{'Alignment ' . $alignment_iterator}{'Intron ' .
				$intron_iterator}{'Size'} = $coordinates->{'Alignment ' .
				$alignment_iterator}{'Exon ' .
				($intron_iterator+1)}{'Genomic'}{'Start'} -
				$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' .
				$intron_iterator}{'Genomic'}{'End'};
		}

		# Store the number of alignments found in the coordinates Hash Ref.
		$coordinates->{'Number of Alignments'} = $alignment_iterator;
	}

	return $coordinates;
}

__PACKAGE__->meta->make_immutable;

1;
