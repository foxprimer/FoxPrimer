package FoxPrimer::Model::mRNA_Primer_Design::Sim4_Alignment;
use Moose;
use namespace::autoclean;
use Bio::Tools::Run::Alignment::Sim4;
use Data::Dumper;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::mRNA_Primer_Design::Sim4_Alignment - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 sim4_alignment

This subroutine is called by FoxPrimer::Model::mRNA_Primer_Design
to align mRNA to genomic DNA and determine the intron/exon boundaries
for each potential alignment.

=cut


sub sim4_alignment {
	my ($self, $structure) = @_;
	foreach my $mrna ( @$structure ) {
		# Create a Bio::Tools::Run::Alignment::Sim4 object with
		# the cDNA sequence defined as the Fasta sequence file
		# containing the cDNA sequence and the genomic sequence
		# as the file containing the genomic DNA sequence
		my $sim4 = Bio::Tools::Run::Alignment::Sim4->new(
			cdna_seq		=>	$mrna->{rna_fh},
			genomic_seq		=>	$mrna->{dna_fh},
		);
		# Use Sim4 to align the cDNA to the genomic DNA
		my @exon_sets = $sim4->align;
		# Define an integer to iterate through the 
		# alignments found by Sim4
		my $alignment_iterator = 1;
		# Iterate through the alignments found by Sim4 and
		# extract the coordinates, storing them in the 'coordinates'
		# key value for each mRNA in the structure.
		foreach my $set ( @exon_sets ) {
			# Define an integer to iterate through the number of exons
			# determined by Sim4
			my $exon_iterator = 1;
			# Iterate through the exons defined by Sim4
			foreach my $exon ( $set->sub_SeqFeature ) {
				# Store the genomic DNA start position for this exon and alignment
				$mrna->{coordinates}{'Alignment ' . $alignment_iterator}{'Exon ' . $exon_iterator}{'Genomic'}{'Start'} = $exon->start;
				# Store the genomic DNA stop position for this exon and alignment
				$mrna->{coordinates}{'Alignment ' . $alignment_iterator}{'Exon ' . $exon_iterator}{'Genomic'}{'End'} = $exon->end;
				# Store the cDNA start position for this exon and alignment
				$mrna->{coordinates}{'Alignment ' . $alignment_iterator}{'Exon ' . $exon_iterator}{'mRNA'}{'Start'} = $exon->est_hit->start;
				# Store the cDNA stop position for this exon and alignment
				$mrna->{coordinates}{'Alignment ' . $alignment_iterator}{'Exon ' . $exon_iterator}{'mRNA'}{'End'} = $exon->est_hit->end;
				# Increase the exon iterator
				$exon_iterator++;
			}
			# The number of introns is always one less than the number of exons.
			# Store this number for this alignment.
			$mrna->{coordinates}{'Alignment ' . $alignment_iterator}{'Number of Exons'} = $exon_iterator-1;
			# For each of the introns defined by Sim4, calculate the size of the intron.
			# This is accomplished by subtracting the stop position from the upstream exon
			# from the stop position of the downstream exon.
			for ( my $intron_iterator = 1; $intron_iterator < ($exon_iterator-1); $intron_iterator++ ) {
				$mrna->{coordinates}{'Alignment ' . $alignment_iterator}{'Intron ' . $intron_iterator}{'Size'} = $mrna->{coordinates}{'Alignment ' . $alignment_iterator}{'Exon ' . ($intron_iterator+1)}{'Genomic'}{'Start'} - $mrna->{coordinates}{'Alignment ' . $alignment_iterator}{'Exon ' . $intron_iterator}{'Genomic'}{'End'};
			}
			# Increase the alignment interator
			$alignment_iterator++;
		}
		# Store the number of alignments found by subtracting 1 from the alignment
		# iterator
		$mrna->{coordinates}{'Number of Alignments'} = $alignment_iterator - 1;
	}
	# Return the structure with the intron and exon coordinates added for each mRNA
	# to the mRNA_Primer_Design Model
	return $structure;
}

__PACKAGE__->meta->make_immutable;

1;
