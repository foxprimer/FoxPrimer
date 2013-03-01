package FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankToFasta;
use Moose;
use namespace::autoclean;
use Bio::SeqIO;
use FindBin;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankToFasta - Catalyst Model

=head1 DESCRIPTION

This module writes the sequence objects fetched from NCBI to FASTA-format
sequence files.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 cdna_object

This Moose object contains the cDNA sequence object from which the sequence
will be written to file.

=cut

has cdna_object	=>	(
	is			=>	'ro',
	isa			=>	'Bio::Seq::RichSeq',
);

=head2 genomic_dna_object

This Moose object contains the genomic DNA sequence object from which the
sequence will be written to file.

=cut

has genomic_dna_object	=>	(
	is			=>	'ro',
	isa			=>	'Bio::Seq',
);

=head2 mrna

This Moose object contains the RefSeq Accession string for the cDNA and
genomic DNA sequences being written to file.

=cut

has mrna	=>	(
	is		=>	'ro',
	isa		=>	'Str',
);

=head2 write_to_fasta

This subroutine write the sequence objects to file, and returns the string
file location to the cDNA and genomic DNA FASTA files.

=cut

sub write_to_fasta {
	my $self = shift;

	# Pre-define a scalar string for the base location of the FASTA files.
	my $fh_base = "$FindBin::Bin/../tmp/fasta/";

	# Define scalar strings for the cDNA and genomic DNA FASTA files.
	my $cdna_fh = $fh_base . $self->mrna . '.mRNA.fa';
	my $genomic_fh = $fh_base . $self->mrna . '.gdna.fa';

	# Write the sequences to file using Bio::SeqIO.
	my $cdna_seqout = Bio::SeqIO->new(
		-file	=>	">$cdna_fh",
		-format	=>	'Fasta',
	);
	$cdna_seqout->write_seq($self->cdna_object);
	my $genomic_seqout = Bio::SeqIO->new(
		-file	=>	">$genomic_fh",
		-format	=>	'Fasta',
	);
	$genomic_seqout->write_seq($self->genomic_dna_object);

	return ($cdna_fh, $genomic_fh);
}

__PACKAGE__->meta->make_immutable;

1;
