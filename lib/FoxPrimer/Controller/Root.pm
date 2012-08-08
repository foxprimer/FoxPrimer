package FoxPrimer::Controller::Root;
use Moose;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in FoxPrimer.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

FoxPrimer::Controller::Root - Root Controller for FoxPrimer

=head1 DESCRIPTION

This is the controller root for the FoxPrimer application. It handles
the data-verification and transfer of information between the View 
and the Model.

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Load the default page for FoxPrimer. This page will display
	# the default page for the application, with brief descriptions 
	# of methods and usage for the application.
    $c->stash(
		template	=>	'home.tt',
		status_msg		=>	'Welcome to the FoxPrimer qPCR Primer Design Suite!',
	);
}

=head2 mrna_primer_design

Form for entering mRNA accessions and returning designed primers
to the user.

=cut

sub mrna_primer_design_shell :Local {
	my ($self, $c) = @_;
	$c->stash(
			template	=>	'mrna_primer_design.tt',
			status_msg	=>	'Please fill out the form below to begin making primers',
	);
}

sub mrna_primer_design :Chained('/') :PathPart('mrna_primer_design') :Args(0) {
	# Default paramets passed to a zero-argument part path
	my ($self, $c) = @_;
	# Predeclare the structure which we will place all the variables
	# from the body of the HTML
	my $structure;
	$structure->{species}		=	$c->req->body_params->{species};
	$structure->{genes}			=	$c->req->body_params->{genes};
	# remove whitespace from the genes field
	$structure->{genes} =~ s/\s//g;
	# if the user has entered a blank field in the genes field
	# return an error
	if ( $structure->{genes} eq '' ) {
		$c->stash(
				error_msg	=>	'You must enter an NCBI mRNA accession',
				template	=>	'mrna_primer_design.tt',
		);
	} else {
		# predeclare an arrayref to hold the list of ncbi accessions
		my $genes = [];
		# if there is more than one accession listed, split them by
		# the comma-delimiter
		if ($structure->{genes} =~ /,/) {
			my @temp_genes = split(/,/, $structure->{genes});
			foreach my $temp_gene(@temp_genes) {
				push (@$genes, $temp_gene);
			}
		} else {
			push (@$genes, $structure->{genes});
		}
		$structure->{accessions} = $genes;
		if ($structure->{accessions} eq '') {
			$c->stash(
			error_msg	=>	'You must enter an NCBI mRNA accession',
			template	=>	'mrna_primer_design.tt',
			);
		} else {
			$structure->{product_size}	=	$c->req->body_params->{product_size};
			# remove whitespace from the product size field
			$structure->{product_size} =~ s/\s//g;
			# predeclare variables for the minimum and maximum product sizes defined
			# in the product size field 
			my ($product_min, $product_max);
			# use regular expressions to extract min and max product sizes from the
			# product size field
			if ($structure->{product_size} =~ /^(\d+)-(\d+)$/) {
				$product_min = $1;
				$product_min = int($product_min + 0.5);
				$product_max = $2;
				$product_max = int($product_max + 0.5);
				$structure->{intron_size} = $c->req->body_params->{intron_size};
				# remove whitespace from the intron size field
				$structure->{intron_size} =~ s/\s//g;
				# test the intron size field to ensure that it is an integer
				if ( $structure->{intron_size} =~ /^\d+$/ ) {
					$structure->{number_per_type} = $c->req->body_params->{number_per_type};
					# remove whitespace from the number per type field
					$structure->{number_per_type} =~ s/\s//g;
					# test the number per type field to ensure that it is an integer
					unless ( $structure->{number_per_type} =~ /^\d+$/ ) {
						$c->stash(
								error_msg	=>	"You must enter an integer value as the number per type",
								templare	=>	'mrna_primer_design.tt',
						);
					}
					# This subroutine checks the database of accessions, gis and genomic
					# coordinates for the user-entered accessions, returns an arrayref of
					# accessions not found in the database
					my ($valid_accessions, $list_of_found_accessions);
					my $invalid_accessions = [];
					my $rs = $c->model('Valid_mRNA::Gene2accession')->search({
							-or	=>	[
								'mrna'		=>	[@$genes],
								'mrna_root'	=>	[@$genes],
							],
						}
					);
					while ( my $result = $rs->next ) {
						unless ( defined ( $list_of_found_accessions->{$result->mrna} ) ) {
							$list_of_found_accessions->{$result->mrna} = 1;
						}
						unless ( defined ( $list_of_found_accessions->{$result->mrna_root} ) ) {
							$list_of_found_accessions->{$result->mrna_root} = 1;
						}
						push ( @{$valid_accessions->{$result->mrna}}, join("\t", $result->mrna, $result->mrna_gi, $result->dna_gi,
							$result->dna_start, $result->dna_stop, $result->orientation));
					}
					$structure->{valid_accessions} = $valid_accessions;
					# if accessions are not found in the database they are returned to the
					# user as a string of accessions in the error message field. If any
					# accessions entered are valid, these are sent to the create primers
					# subroutine and the results are returned to the user.
					foreach my $gene (@$genes) {
						unless ( defined( $list_of_found_accessions->{$gene} ) ) {
							push (@$invalid_accessions, $gene);
						}
					}
					if ( defined (%$valid_accessions) ) {
						my $number_of_valid_accessions = 0;
						foreach my $valid_accession ( keys $valid_accessions ) {
							$number_of_valid_accessions++;
						}
						my $total_number_to_make = @$genes;
						if ( $number_of_valid_accessions == $total_number_to_make ) {
							my $return_accessions = $c->model('mRNA_Primer_Design')->create_primers($structure);
							my $primer_results = $c->model('Created_Primers::Primer')->search(
										{ 'mrna'	=>	$return_accessions },
										{ order_by	=>	{ -asc	=>	'product_penalty'} }
									);
							$c->stash(
									structure		=>	$structure,
									primer_results	=>	$primer_results,
									template		=>	'mrna_primer_design.tt',
									status_msg		=>	'Your primers have been designed!',
							);
						} else {
							my $error_string = join(", ", @$invalid_accessions);
							my $return_accessions = $c->model('mRNA_Primer_Design')->create_primers($structure);
							my $primer_results = $c->model('Created_Primers::Primer')->search(
										{ 'mrna'	=>	$return_accessions },
										{ order_by	=>	{ -asc	=>	'product_penalty'} }
									);
							$c->stash(
									structure		=>	$structure,
									error_msg		=>	"Unfortunately, the following accessions were not found in our NCBI:gene2accession database: $error_string",
									primer_results	=>	$primer_results,
									template		=>	'mrna_primer_design.tt',
							);
						}
					} else {
						my $error_string = join(", ", @$invalid_accessions);
						$c->stash(
							template		=>	'mrna_primer_design.tt',
							error_msg		=>	"Unfortunately, the following accessions were not found in our NCBI:gene2accession database: $error_string",
						);
					}
				} else {
					$c->stash(
								error_msg	=>	"You must enter an integer value for the intron size",
								template	=>	'mrna_primer_design.tt',
					);
				}
			} else {
				$c->stash(
						error_msg	=>	"You must enter integer values for the product sizes and the product min and product max seperated by a hyphen '-'.",
						template	=>	'mrna_primer_design.tt',
				);
			}
		}
	}
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
