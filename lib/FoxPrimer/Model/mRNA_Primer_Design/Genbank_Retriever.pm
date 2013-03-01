package FoxPrimer::Model::mRNA_Primer_Design::Genbank_Retriever;
use Moose;
use namespace::autoclean;
use Bio::DB::GenBank;
use Data::Dumper;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::mRNA_Primer_Design::Genbank_Retriever - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 get_objects

This subroutine is called by FoxPrimer::Model::mRNA_Primer_Design
to interact with Genbank to retrieve mRNA and Genomic BioPerl
objects, as well as a gene description string.

=cut

sub get_objects {
	my ($self, $structure) = @_;
	# Iterate through the structure and interact with NCBI through
	# BioPerl to fetch the sequence objects and gene description
	my ($mrna_accession, $mrna_gi, $dna_gi, $dna_start, $dna_stop,
		$orientation) ;
	foreach my $container ( @$structure ) {
		# Create a new GenBank instance
		my $rna_bank = Bio::DB::GenBank->new();
		# Fetch an RNA object from GenBank using the RNA GI extracted from the NCBI
		# Gene2accession database.
		# Fetching the RNA object from GenBank is the most time-consuming portion
		# of this program.
		$container->{mrna_object} = $rna_bank->get_Seq_by_gi($container->{mrna_gi});
		# Extract the description from the RNA object and store is as a string in the
		# container
		$container->{description} = $container->{mrna_object}->desc();
		# The strand needs to be either a 1 or a 2, positive or negative respectively,
		# in order for Bio::DB::GenBank to extract the appropriate genomic DNA object
		if ( $container->{orientation} eq '+' ) {
			$container->{strand} = 1;
		} elsif ( $container->{orientation} eq '-' ) {
			$container->{strand} = 2;
		}
		my $dna_bank = Bio::DB::GenBank->new(
			-format		=>	'Fasta',
			-seq_start	=>	$container->{dna_start},
			-seq_stop	=>	$container->{dna_stop},
			-strand		=>	$container->{strand},
		);
		$container->{dna_object} = $dna_bank->get_Seq_by_acc($container->{dna_gi});
	}
	return $structure;
}
__PACKAGE__->meta->make_immutable;

1;
