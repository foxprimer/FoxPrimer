package FoxPrimer::Model::mRNA_Primer_Design::Create_Fasta_Files;
use Moose;
use namespace::autoclean;
use Bio::SeqIO;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::mRNA_Primer_Design::Create_Fasta_Files - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 write_to_fasta

This subroutine takes the accession, mrna, and genomic objects as arguments
and writes the mrna and genomic objects to file defined by the accession.
The filename for the mrna and dna are returned to FoxPrimer::Model::mRNA_Primer_Design

=cut

sub write_to_fasta {
	my ($self, $structure) = @_;
	# Iterate through the RNA containers in the structure
	foreach my $container ( @$structure ) {
		# Create the file handle strings for the Fasta files that will be written
		$container->{rna_fh} = 'tmp/fasta/' . $container->{mrna} . '.mRNA.fa';
		$container->{dna_fh} = 'tmp/fasta/' . $container->{mrna} . '.dna.fa';
		# Use the _fasta_io subroutine to write the sequence from each sequence
		# object to file
		$self->_fasta_io($container->{mrna_object}, $container->{rna_fh});
		$self->_fasta_io($container->{dna_object}, $container->{dna_fh});
	}
	return ($structure);
}

=head2 _fasta_io

This private subroutine writes the sequence to file.

=cut

sub _fasta_io {
	my ($self, $sequence_object, $file_handle) = @_;
	my $seqout = Bio::SeqIO->new(
		-file	=>	">$file_handle",
		-format	=>	'Fasta',
	);
	$seqout->write_seq($sequence_object);
}

__PACKAGE__->meta->make_immutable;

1;
