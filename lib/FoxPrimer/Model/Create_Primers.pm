package FoxPrimer::Model::Create_Primers;
use Moose;
use namespace::autoclean;
use Bio::SeqIO;
use FoxPrimer::Model::Updated_Primer3_Run;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::Create_Primers - Catalyst Model

=head1 DESCRIPTION

This module interfaces with Primer3 to create several
hundred primer pairs for each user-defined mRNA sequence.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 make_primer_pairs

This subroutine is called by FoxPrimer::Model::mRNA_Primer::Design
and is passed the file handle for the mRNA fasta file, the species,
and the product size range string. This module is dependent on an
updates (patchwork-rewritten) version of Bio::Tools::Run::Primer3
that is modified to use the latest version of Primer3.

=cut

sub make_primer_pairs {
	my ($self, $rna_fh, $species, $product_size) = @_;
	my $seqio = Bio::SeqIO->new(
		-file	=>	$rna_fh,
	);
	my $seq = $seqio->next_seq;
	my $primer3_path = `which primer3_core`;
	chomp ($primer3_path);
	my $primer3 = FoxPrimer::Model::Updated_Primer3_Run->new(
		-seq		=>	$seq,
		-outfile	=>	"temp.out",
		-path		=>	$primer3_path,
	);
	my $misprime_fh;
	if ( $species eq 'Human' ) {
		$misprime_fh = 'root/static/files/human_and_simple';
	} elsif ( $species eq 'Rodent and Simple' ) {
		$misprime_fh = 'root/static/files/rodent_and_simple';
	} else {
		die "Invalid specied field used\n";
	}
	unless ($primer3->executable) {
		die "Primer3 can not be found. It is installed in a system-wide path?";
	}
	$primer3->add_targets(
		'PRIMER_MISPRIMING_LIBRARY'	=>	$misprime_fh,
		'PRIMER_NUM_RETURN'			=>	500,
		'PRIMER_PRODUCT_SIZE_RANGE'	=>	$product_size,
	);
	my $results = $primer3->run;
}

__PACKAGE__->meta->make_immutable;

1;
