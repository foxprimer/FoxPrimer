package FoxPrimer::Model::PrimerDesign;
use Moose;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Schema;
use FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign;
use namespace::autoclean;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PrimerDesign - Catalyst Model

=head1 DESCRIPTION

This is the main subroutine called by the FoxPrimer Controller module to
check the user forms and entries to ensure that valid data will be passed
to the primer design algorithms. Once the information has passed the
required tests, this module will create instances of mRNA_Primer_Design or
ChIP_Primer_Design as required.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 product_size_string

This Moose object is used to store the user-defined product size string. By
default it is set to 70-150 (bp) as it is in the Template Toolkit webpage,

=cut

has product_size_string	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 max_number_per_type

This Moose object is used to store the administrator-defined max value for
the number of cDNA primers that will be made for each type of primer.

=cut

has max_number_per_type	=> (
	is			=>	'ro',
	isa			=>	'Int',
	required	=>	1,
	# Change the default value here based on your server limitations.
	default		=>	10,
	lazy		=>	1,
);

=head2 number_per_type

This Moose object is defined by the user in the webpage as the number of
primer pairs they wish to make per type. This value will be contrained by
the administrator-defined maximum value.

=cut

has number_per_type =>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 intron_size

This Moose object is defined by the user in the webpage as the minimum
intron size to be used when defining the type of primer pair types.

=cut

has intron_size =>	(
	is			=>	'ro',
	isa			=>	'Str'
);

=head2 accessions_string

This Moose object holds the string of RefSeq mRNA accessions that the user
would like to create cDNA primers for.

=cut

has accessions_string	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 species

This Moose object is defined by the use in the dropdown box, and will be
used to determine which mispriming file is appropriate for primer3.

=cut

has species	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 gene2accession_schema

This Moose object is created by a lazy loader, which will create a
DBIx::Class::ResultSet object for the Gene2Accession database. This object
is private and can not be modified upon creation of a
FoxPrimer::Model::PrimerDesign object.

=cut

has _gene2accession_schema	=>	(
	is			=>	'ro',
	isa			=>	'FoxPrimer::Schema',
	default		=>	sub {
		my $self = shift;
		my $dsn = "dbi:SQLite:$FindBin::Bin/../db/gene2accession.db";
		my $schema = FoxPrimer::Schema->connect($dsn, '', '', '');
		return $schema;
	},
	required	=>	1,
	reader		=>	'gene2accession_schema',
);

=head2 validate_mrna_form

This subroutine is called by the FoxPrimer Controller module to ensure that
the fields entered by the user for the creation of cDNA primers is valid.
This subroutine will return any error messages to the Controller in the
form of an Array Ref, and it will return an Array Ref of Hash Refs of the
information needed to design primers once the other fields have been
validated. This subroutine will also return an Array Ref of messages about
RefSeq mRNA accessions entered by the user, which were not found or not
valid.

=cut

sub validate_mrna_form {
	my $self = shift;

	# Pre-declare an Array Ref to hold any error messages to return to the
	# user.
	my $form_errors = [];

	# Determine if the field entered for the product size is valid by
	# running the FoxPrimer::Model::PrimerDesign::validate_product_size
	# subroutine.
	my $product_size_errors = $self->validate_product_size;

	# If there are any errors, add them to the form_errors Array Ref
	if (@$product_size_errors) {
		push(@$form_errors, @$product_size_errors);
	}

	# Determine if the number to make field is valid by running the
	# FoxPrimer::Model::PrimerDesign::validate_number_per_type subroutine.
	my $number_per_type_errors = $self->validate_number_per_type;

	# If there are any errors, add them to the form_errors Array Ref
	if (@$number_per_type_errors) {
		push(@$form_errors, @$number_per_type_errors);
	}

	# Determine if the minimum intron size field is valid by running the
	# FoxPrimer::Model::PrimerDesign::validate_intron_size subroutine.
	my $intron_size_errors = $self->validate_intron_size;

	# If there are any errors, add them to the form_errors Array Ref
	if (@$intron_size_errors) {
		push(@$form_errors, @$intron_size_errors);
	}

	# If there are any errors in the fields checked this far, do not check
	# to see if the mRNAs entered were valid. Return the error messages to
	# the user and end.
	if ( @$form_errors ) {
		return($form_errors, [], []);
	} else {
		# Run the valid_refseq_accessions subroutine, and return the
		# results to the Controller.
		my ($accession_errors, $accessions_to_make_primers) =
		$self->valid_refseq_accessions;
		return ($form_errors, $accession_errors,
			$accessions_to_make_primers
		);
	}
}

=head2 validate_product_size

This subroutine is called to test that the product size entered in the form
is correct.

=cut

sub validate_product_size {
	my $self = shift;

	# Pre-declare an Array Ref to hold error messages to be returned to the
	# user.
	my $field_errors  = [];

	# Test to make sure the field is valid for entry into Primer3. Make
	# sure that both fields are integers and are joined by a '-' hyphen
	# without any whitespace.
	if ( $self->product_size_string =~ /-/ &&
		$self->product_size_string =~ /\d+-\d+/ ) {
		my ($lower_limit, $upper_limit) = split(/-/,
			$self->product_size_string);

		# Make sure that the lower limit is less than the upper limit.
		unless ( $upper_limit > $lower_limit ) {
			push(@$field_errors,
				"The product size upper limit must be larger than the " .
				"product size lower limit"
			);
		}
	} else {
		push(@$field_errors, "The product size field must be two integers "
			. "separated by a '-' with no whitespace."
		);
	}

	return $field_errors;
}

=head2 validate_number_per_type

This subroutine is called to ensure that the value defined by the user for
the number of primers to be made for each primer type is both a non-zero
integer and is less than or equal to the maximum number of primers to be
designed as specified by the administrator.

=cut

sub validate_number_per_type {
	my $self = shift;

	# Pre-declare an Array Ref to hold any error messages to be returned to
	# the user.
	my $field_errors = [];

	# Make sure that the number_per_type is greater than zero
	unless ( $self->number_per_type > 0 ) {
		push(@$field_errors,
			"The number of primers per type field must contain a non-zero "
			. "integer."
		);
	}

	# Make sure that the number_per_type is less than the
	# max_number_per_type
	unless ( $self->number_per_type <= $self->max_number_per_type ) {
		push(@$field_errors,
			"The number of primers per type field maximum value is: " .
			$self->max_number_per_type . ". Please contact the " .
			"administrator if you feel this does not meet your needs."
		);
	}

	return $field_errors;
}

=head2 validate_intron_size

This subroutine is called to make sure that the minimum intron size defined
by the user is a non-zero integer.

=cut

sub validate_intron_size {
	my $self = shift;

	# Pre-declare an Array Ref to hold error messages to return to the
	# user.
	my $field_errors = [];

	# Test to make sure that the intron_size is greater than zero.
	unless ( $self->intron_size > 0 ) {
		push(@$field_errors,
			"The intron size field must be a non-zero integer"
		);
	}

	return $field_errors;
}

=head2 valid_refseq_accessions

This subroutine interacts with the gene2accession database (created from
the NCBI flatfile) to search for the GI accession for NCBI (for much faster
access to the NCBI database), the start and stop positions of the mRNA on
the genomic DNA, and which strand of genomic DNA the mRNA is found. If the
mRNA specified by the user is not found in the database, it will be
returned to the user in an error message.

=cut

sub valid_refseq_accessions {
	my $self = shift;

	# Pre-declare an Array Ref to hold error messages to return to the
	# user.
	my $error_messages = [];

	# Pre-declare an Array Ref to hold the accessions to be tested
	my $accessions_to_test = [];

	# Copy the accessions_string into a scalar
	my $accessions_string = $self->accessions_string;

	# Remove any whitespace from the accessions string
	$accessions_string =~ s/\s//g;

	# First, make sure that there is an accessions string.
	unless ($accessions_string) {
		push(@$error_messages,
			"You must enter a RefSeq mRNA accession to design cDNA primers"
		);
		return ($error_messages, []);
	}

	# Test to see if the user has entered more than one RefSeq mRNA
	# accession, which should be delimited by a comma character ','.
	if ( $accessions_string =~ /,/ )  {
		push(@$accessions_to_test, split(/,/, $accessions_string));
	} else {
		push(@$accessions_to_test, $accessions_string);
	}

	# Create a resultset for the Gene2accession database.
	my $gene2accession_result_set =
	$self->gene2accession_schema->resultset('Gene2accession');

	# Pre-declare an Array Ref to hold the information for accessions that
	# are found in the gene2accession database.
	my $accessions_to_make_primers = [];

	# Iterate through the accessions_to_test, and search the gene2accession
	# database for each one. If the accession is found in the database,
	# store the relevant information in the accessions_to_make_primers
	# Array Ref. If not, add a string to the error_messages Array Ref.
	foreach my $accession_to_test (@$accessions_to_test) {
		my $search_result = $gene2accession_result_set->search(
			{
				-or	=>	
				[
					'mrna'		=>	$accession_to_test,
					'mrna_root'	=>	$accession_to_test,
				]
			}
		);

		# Make sure that a result has been found. If not, add an error
		# message string to the error_messages.
		if ( $search_result->next ) {
			$search_result->reset;

			while ( my $found_rna = $search_result->next ) {
				push(@$accessions_to_make_primers,
					{
						mrna		=>	$found_rna->mrna,
						mrna_gi		=>	$found_rna->mrna_gi,
						dna_gi		=>	$found_rna->dna_gi,
						dna_start	=>	$found_rna->dna_start,
						dna_stop	=>	$found_rna->dna_stop,
						orientation	=>	$found_rna->orientation,
					}
				);
			}
		} else {

			# Add an error message.
			push(@$error_messages,
				"The accession you have entered: $accession_to_test " .
				"was not found in the NCBI gene2accession database. " .
				"Please check that you have entered the accession" .
				" correctly, and if you are trying to enter multiple " .
				"accessions please use a comma to seperate them."
			);
		}
	}

	return ($error_messages, $accessions_to_make_primers);
}

__PACKAGE__->meta->make_immutable;

1;
