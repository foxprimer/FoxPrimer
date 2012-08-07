package FoxPrimer::Model::mRNA_Primer_Design;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use FoxPrimer::Model::Genbank_Retreival;
use FoxPrimer::Model::Create_Fasta_Files;
use FoxPrimer::Model::Sim4_Alignment;
use FoxPrimer::Model::Create_Primers;
use FoxPrimer::Model::Primer_Info;
use FoxPrimer::Model::Map_Primers;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::mRNA_Primer_Design - Catalyst Model

=head1 DESCRIPTION

This module is the controller which calls submodules
to create qRT-PCR primers. 

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 create_primers

This subroutine is called by the Controller to control the processing
of user-entered data into the creation of qPCR primers.

=cut

sub create_primers {
	my ($self, $structure) = @_;
	# First extract the revelant information from the structure hash
	# reference
	# The $species variable determines which mispriming library will
	# be used by Primer3
	my $species = $structure->{species};
	# The $product_size variable holds a string which tells primer3
	# the range of products sizes to allow
	my $product_size = $structure->{product_size};
	# The $intron_size variable hols the integer which will be used
	# to determine which primer pairs flank introns larger than the
	# user-defined minimum
	my $intron_size = $structure->{intron_size};
	# The $number_per_type variable holds the integer value that will
	# be used to determine the maximum number of each type of primer 
	# pare that will be discovered and returned to the user
	my $number_per_type = $structure->{number_per_type};
	# The $accessions variable is a hash reference of arrays containing
	# the NCBI mRNA accession as the key value containing an array of
	# tab delimited RNA Accession, RNA GI, DNA GI, Genomic Start,
	# Genomic Stop, and Orientation
	my $accessions = $structure->{valid_accessions};
	my ($return_accessions, $seen_accessions);
	foreach my $accession ( keys %$accessions ) {
		foreach my $gis_and_coordinates_line ( @{$accessions->{$accession}} ) {
			my ($rna_accession, $rna_gi, $dna_gi, $dna_start, $dna_stop,
				$orientation) = split(/\t/, $gis_and_coordinates_line);
			print "RNA ACCESSION $rna_accession\nORIENTATION $orientation\n";
			my ($description, $rna_object, $dna_object) = FoxPrimer::Model::Genbank_Retreival->get_objects($gis_and_coordinates_line);		
			my ($rna_fh, $dna_fh) = FoxPrimer::Model::Create_Fasta_Files->write_to_fasta($rna_accession, $rna_object, $dna_object);
			my ($coordinates) = FoxPrimer::Model::Sim4_Alignment->sim4_alignment($rna_fh, $dna_fh);
			FoxPrimer::Model::Create_Primers->make_primer_pairs($rna_fh, $species, $product_size);
			my $primer_results = FoxPrimer::Model::Primer_Info->extract_primer_pairs;
			my $mapped_primers = FoxPrimer::Model::Map_Primers->map_primers($coordinates, $primer_results, $number_per_type, $intron_size);
			FoxPrimer::Model::Primer_Database->prepare_insert_lines($mapped_primers, $description, $rna_accession);
			unless ( defined ( $seen_accessions->{$rna_accession} ) ) {
				push (@$return_accessions, $rna_accession);
				$seen_accessions->{$rna_accession} = 1;
			}
		}
	}
	`rm *.fa`;
	return $return_accessions;
}

__PACKAGE__->meta->make_immutable;

1;
