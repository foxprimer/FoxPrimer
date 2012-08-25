package FoxPrimer::Model::mRNA_Primer_Design;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use FoxPrimer::Model::ChIP_Primer_Design;
use FoxPrimer::Schema;
use FoxPrimer::Model::mRNA_Primer_Design::Genbank_Retriever;
use FoxPrimer::Model::mRNA_Primer_Design::Create_Fasta_Files;
use FoxPrimer::Model::mRNA_Primer_Design::Sim4_Alignment;
use FoxPrimer::Model::mRNA_Primer_Design::Primer3;
use FoxPrimer::Model::mRNA_Primer_Design::Map_Primers;

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

=head2 Moose declarations

This sections contains declarations for constructor methods for 
object-oriented code.

=cut

has number_per_type	=>	(
	is		=>	'rw',
	isa		=>	'Int',
);

has intron_size		=>	(
	is		=>	'rw',
	isa		=>	'Int',
);

has product_size	=>	(
	is		=>	'rw',
	isa		=>	'Str',
);

has valid_accessions	=>	(
	is		=>	'rw',
	isa		=>	'ArrayRef[HashRef]',
);

has species				=>	(
	is		=>	'rw',
	isa		=>	'Str',
);

has mispriming_file		=>	(
	is				=>	'rw',
	isa				=>	'Str',
	default			=>	sub {
		my $self = shift;
		my $species = $self->species;
		# Pre-declare a string to hold the file location based on the species
		my $mispriming_fh = '';
		if ( $species eq 'Human' ) {
			$mispriming_fh = 'root/static/files/human_and_simple';
		} else {
			$mispriming_fh = 'root/static/files/rodent_and_simple';
		}
		return $mispriming_fh;
	},
	required		=>	1,
	lazy			=>	1,
);

has primer3_executable	=>	(
	is				=>	'rw',
	isa				=>	'Str',
	default			=>	sub {
		my $self = shift;
		my $primer3_path = `which primer3_core`;
		chomp $primer3_path;
		return $primer3_path;
	},
	required		=>	1,
	lazy			=>	1,
);

=head2 create_primers

This subroutine is called by the Controller to control the processing
of user-entered data into the creation of qPCR primers.

=cut

sub create_primers {
	my $self = shift;
	# Pre-declare structure to be an Array Ref
	my $structure = [];
	# Fetch the sequence objects and store them in an Array Ref of Hash Refs called structure
	$structure = FoxPrimer::Model::mRNA_Primer_Design::Genbank_Retriever->get_objects($self->valid_accessions);		
	# Write the sequences from sequences objects to file and store the temporary filehandles
	# in the structure
	$structure = FoxPrimer::Model::mRNA_Primer_Design::Create_Fasta_Files->write_to_fasta($structure);
	# Align the mRNA sequence to the DNA sequence using Sim4.
	# Then, calculate the splice-junction positions and store them in the structure.
	$structure = FoxPrimer::Model::mRNA_Primer_Design::Sim4_Alignment->sim4_alignment($structure);
	# Create a FoxPrimer::Model::mRNA_Primer_Design::Primer3 object and create primers
	my $primer3 = FoxPrimer::Model::mRNA_Primer_Design::Primer3->new(
		mispriming_file		=>	$self->mispriming_file,
		product_size		=>	$self->product_size,
		primer3_path		=>	$self->primer3_executable,
	);
	# Pre-declare an Array Ref to hold error messages in case primers were not able to
	# be designed for any mRNAs
	my $error_messages = [];
	($error_messages, $structure) = $primer3->create_primers($structure);
	# Remove the temporary fasta files
	`rm tmp/fasta/*.fa`;
	# Remove the temporary Primer3 out file
	`rm tmp/primer3/temp.out`;
	# Check to make sure that primers have been created for at least one
	# of the mRNAs
	if ( @$structure ) {
		# Call the map subroutine from the Model FoxPrimer::Model::mRNA_Primer_Design::Map_Primers
		# to return an Array Ref of Hash Refs, which will be used to make a populate call to insert
		# into the database
		my $map_primers = FoxPrimer::Model::mRNA_Primer_Design::Map_Primers->new(
			intron_size			=>	$self->intron_size,
			number_per_type		=>	$self->number_per_type,
		);
		my $primers_insert = $map_primers->map($structure);
		return ($error_messages, $primers_insert);
	}
	return $error_messages;
}

=head2 validate_form

This subroutine is called by the Catalyst Controller to make sure that all of the fields
have been filled by the user, and that each field has valid information.

=cut

sub validate_form {
	my ($self, $structure) = @_;
	# Pre-declare an Array Ref to hold error messages to be returned to the user.
	my $form_errors = [];
	# For each field entered in the form, remove all of the whitespace
	foreach my $field ( keys %$structure ) {
		$structure->{$field} =~ s/\s//g;
	}
	# Check that the user has entered the appropriate information in the product size
	# field. To do this, use the validate_product_size subroutine from the Model 
	# ChIP_Primer_Design
	my $product_size_check = FoxPrimer::Model::ChIP_Primer_Design->new();
	my $product_size_errors = $product_size_check->validate_product_size($structure);
	push(@$form_errors, @$product_size_errors) if $product_size_errors;
	# Check to make sure that the intron size field is an Integer greater than zero
	unless ( ($structure->{intron_size} =~ /^\d+$/) && ($structure->{intron_size} > 0)  ) {
		push(@$form_errors, "The product size '$structure->{intron_size}' is not valid. It must be an integer greater than zero.");
	}
	# Check to make sure that the number of primers returned per type is an integer 
	# value and is not too large for your server/local machine to handle
	# Default max: 20
	my $max_per_type = 20;
	unless ( ($structure->{number_per_type} =~ /^\d+$/) &&
		($structure->{number_per_type} > 0) &&
		($structure->{number_per_type} <= $max_per_type) ) {
		push(@$form_errors, "The defined number of primers to make per type: $structure->{number_per_type} is not valid. It must be an integer greater than zero and less than the server's maximum of $max_per_type.");
	}
	# Return the structure and the errors (if any) to the Catalyst Controller
	return ($form_errors, $structure);
}

=head2 extract_and_validate_accessions

This subroutine is called by the Catalyst controller. It is passed a string
of possible NCBI RNA accessions, that are ','-delimited. These accessions
are extracted from the string and then using the Gene2Accession database
to determine if the accession is valid and return relevant information
about the position of the RNA and the gi's. This information is stored
in the valid_accessions structure.

=cut

sub extract_and_validate_accessions {
	my ($self, $accessions_string) = @_;
	# Pre-declare an Array Ref to hold accessions to test
	my $accessions_to_test = [];
	# Test to see if there are more than one accessions
	if ( $accessions_string =~ /,/ ) {
		@$accessions_to_test = split(/,/, $accessions_string);
	} else {
		push(@$accessions_to_test, $accessions_string);
	}
	# Pre-declare a Hash Ref to store found accessions in the database
	# so that it can be rapidly determined which accessions are valid
	my $found_accessions = {};
	# Pre-declare an Array Ref of Hash Refs to hold the primer information
	my $accessions_to_make_primers = [];
	# Create an instance of the result set of the Gene2accession database
	my $schema = FoxPrimer::Schema->connect('dbi:SQLite:db/gene2accession.db');
	my $result_class = $schema->resultset('Gene2accession');
	# Search the database for the accessions
	my $result_set = $result_class->search(
		{
			-or	=>
			[
				'mrna'		=>	[@$accessions_to_test],
				'mrna_root'	=>	[@$accessions_to_test],
			]
		}
	);
	while ( my $found_rna = $result_set->next ) {
		unless ( defined ( $found_accessions->{$found_rna->mrna} ) ) {
			$found_accessions->{$found_rna->mrna} = 1;
		}
		unless ( defined ( $found_accessions->{$found_rna->mrna_root} ) ) {
			$found_accessions->{$found_rna->mrna_root} = 1;
		}
		push(@$accessions_to_make_primers,
			{
				mrna			=>	$found_rna->mrna,
				mrna_gi			=>	$found_rna->mrna_gi,
				dna_gi			=>	$found_rna->dna_gi,
				dna_start		=>	$found_rna->dna_start,
				dna_stop		=>	$found_rna->dna_stop,
				orientation		=>	$found_rna->orientation,
			}
		);
	}
	# If there are any valid accessions found, store them in the valid accessions
	# object for this model
	if ( $accessions_to_make_primers ) {
		$self->valid_accessions($accessions_to_make_primers);
	}
	# Pre-declare an Array Ref to hold error messages to return to the user
	my $error_messages = [];
	# Iterate through the user-defined primers and see if any of them were found
	# in the Gene2accession database
	foreach my $accession_to_test ( @$accessions_to_test ) {
		unless ( defined ( $found_accessions->{$accession_to_test} ) ||
			defined ( $found_accessions->{$accession_to_test} ) ) {
			push( @$error_messages, "The accession you have entered: $accession_to_test, is either not a valid NCBI RNA accession, or is not found in our database.");
		}
	}
	# If no valid accessions were found, return a boolean false
	# If any were found return a boolean true
	if ( @$accessions_to_test == @$error_messages ) {
		return ($error_messages, 0);
	} else {
		return ($error_messages, 1);
	}
}

__PACKAGE__->meta->make_immutable;

1;
