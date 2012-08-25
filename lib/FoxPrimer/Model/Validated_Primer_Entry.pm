package FoxPrimer::Model::Validated_Primer_Entry;
use Moose;
use namespace::autoclean;
use FoxPrimer::Schema;
use Data::Dumper;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::Validated_Primer_Entry - Catalyst Model

=head1 DESCRIPTION

This model is used by the the Catalyst Controller to determine if the
information entered in the file uploaded for validated primers is valid.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 Moose Declarations

This section contains object-oriented code declared by Moose

=cut

has genome			=>	(
	is				=>	'rw',
	isa				=>	'Str',
);

has gene_body_file	=>	(
	is				=>	'rw',
	isa				=>	'Str',
	default			=>	sub {
		my $self = shift;
		my $genome = $self->genome;
		if ( $genome eq 'mm9' ) {
			return 'root/static/files/Mouse_Gene_Bodies.bed';
		} elsif ( $genome eq 'hg19' ) {
			return 'root/static/files/Human_Gene_Bodies.bed';
		};
	},
	required		=>	1,
	lazy			=>	1,
);

has gene_bodies =>	(
	is				=>	'ro',
	isa				=>	'HashRef[ArrayRef]',
	default			=>	sub {
		my $self = shift;
		my $gene_body_fh = $self->gene_body_file;
		my $accessions = {};
		open my $gene_body_file, "<", $gene_body_fh or die "Could not read from $gene_body_fh $!\n";
		while (<$gene_body_file>) {
			my $line = $_;
			chomp($line);
			my ($chr, $start, $stop, $accession, $score, $strand) = split(/\t/, $line);
			push( @{$accessions->{$accession}}, join("\t", $chr, $start, $stop, $strand));
		}
		return $accessions;
	},
	required		=>	1,
	lazy			=>	1,
);

has chromosome_sizes_file	=>	(
	is				=>	'rw',
	isa				=>	'Str',
	default			=>	sub {
		my $self = shift;
		my $genome = $self->genome;
		if ($genome eq 'mm9') {
			return 'root/static/files/mm9.chrom.sizes';
		} elsif ( $genome eq 'hg19' ) {
			return 'root/static/files/hg19.chrom.sizes';
		}
	},
	required		=>	1,
	lazy			=>	1,
);

has chromosome_sizes	=>	(
	is				=>	'rw',
	isa				=>	'HashRef[Int]',
	default			=>	sub {
		my $self = shift;
		my $chromosome_sizes_fh = $self->chromosome_sizes_file;
		my $chromosome_sizes = {};
		open my $chromosome_sizes_file, "<", $chromosome_sizes_fh or die "Could not read from $chromosome_sizes_fh $!\n";
		while (<$chromosome_sizes_file>) {
			my $line = $_;
			chomp ($line);
			my ($chromosome, $length) = split(/\t/, $line);
			$chromosome_sizes->{$chromosome} = $length;
		}
		return $chromosome_sizes;
	},
	required		=>	1,
	lazy			=>	1,
);

=head2 valid_file

This subroutine is called by the Catalyst Controller and is passed the
file path uploaded by the user. This subroutine then determines if the
information in the file is valid.

This subroutine then returns two things: a Hash Ref of Array Refs
of Hash Refs containing the information for any mRNA primers or ChIP
primers  to be made, and an Array Ref of error messages to return to 
the user.

=cut

sub valid_file {
	my ($self, $uploaded_fh) = @_;
	# Create a Hash Ref structure to hold primer information to be
	# returned to the Catalyst Controller
	my $structure = {};
	# Check to make sure the correct information has been entered in the uploaded file
	open my $validated_primers_file, "<", $uploaded_fh or return (
		{}, ["The file $uploaded_fh was unable to be opened. Please check the permissions on this file"]
	);
	# Create an integer variable that tells the user the line number if there is an error in the file
	my $line_number = 1;
	# Create an Array Ref to hold errors found in the uploaded file
	my $file_errors = [];
	while (<$validated_primers_file>) {
		my $line = $_;
		chomp ($line);
		# Create a boolean variable that will be used to determine whether the information from this primer
		# line will be passed to the Catalyst Model
		my $valid_primer_line = 1;
		my ($primer_type, $left_primer_sequence, $right_primer_sequence, $accession, $user_name,
			$efficiency, $left_primer_chip_location, $right_primer_chip_location, $genome ) = split(/\t/, $line);
		# Make the $primer_type string lowercase
		$primer_type = lc($primer_type);
		# Make sure that the primer type is either 'chip' or 'mrna'
		unless ( $primer_type eq 'chip' || $primer_type eq 'mrna' ) {
			push (@$file_errors, "On line $line_number, the primer type is $primer_type, which is not 'chip' or 'mrna'");
			$valid_primer_line = 0;
		}
		# Make sure that the primer strings entered contain only 'A', 'T', 'G', or 'C'
		$left_primer_sequence = uc($left_primer_sequence);
		$right_primer_sequence = uc($right_primer_sequence);
		unless ( $left_primer_sequence =~ /^[ATGC]$/ ) {
			push (@$file_errors, "On line $line_number, the left primer sequence: $left_primer_sequence, contains one or more invalid characters");
			$valid_primer_line = 0;
		}
		unless ( $right_primer_sequence =~ /^[ATGC]$/ ) {
			push (@$file_errors, "On line $line_number, the right primer sequence: $right_primer_sequence, contains one or more invalid characters");
			$valid_primer_line = 0;
		}
		# Check to make sure that the user has entered their name
		unless ( $user_name ) {
			push (@$file_errors, "On line $line_number, the user name is not defined");
			$valid_primer_line = 0;
		}
		# Check to make sure a numerical value has been entered for the efficiency
		unless ( $efficiency =~ /^\d+\.\d+$|^\d+$/ ) {
			push (@$file_errors, "On line $line_number, the efficiency entered: $efficiency is not a valid number");
			$valid_primer_line = 0;
		}
		# If the primers are defined as mRNA primers, check to make sure the accession is valid
		if ( $primer_type eq 'mrna' ) {
			# This subroutine checks the database of accessions, gis and genomic
			# coordinates for the user-entered accessions, returns an arrayref of
			# accessions not found in the database
			my $valid_accessions = {};
			my $gene2accession_schema = FoxPrimer::Schema->connect("dbi:SQLite:db/gene2accession.db");
			my $gene2accession_result_set = $gene2accession_schema->resultset('Gene2accession');
			$gene2accession_result_set->search({
					-or	=>	[
						'mrna'		=>	[$accession],
						'mrna_root'	=>	[$accession],
					],
				}
			);
			while ( my $result = $gene2accession_result_set->next ) {
				push ( @{$valid_accessions->{$accession}}, 
					{
						accession	=>	$result->mrna,
						mrna_gi		=>	$result->mrna_gi,
						dna_gi		=>	$result->dna_gi,
						dna_start	=>	$result->dna_start,
						dna_stop	=>	$result->dna_stop,
						orienation	=>	$result->orientation,
					}
				);
			}
			# Test to ensure that that mRNA was found in the dispatch table
			unless ( $valid_accessions->{$accession} ) {
				push (@$file_errors, "On line $line_number, the accession: $accession is not found in our gene2accession database");
				$valid_primer_line = 0;
			}
			# If the boolean $valid_primer_line is still true, pass the requisite information to the Array Ref of Hash Refs
			if ( $valid_primer_line == 1 ) {
				push( @{$structure->{mrna_primers_to_design}},
					{
						left_primer_sequence	=>	$left_primer_sequence,
						right_primer_sequence	=>	$right_primer_sequence,
						user_name				=>	$user_name,
						efficiency				=>	$efficiency,
						accession_and_position	=>	$valid_accessions,
					}
				);
			} 
		# If the primers are defined as ChIP primers, check to make sure the reqiured information has been entered
		} elsif ( $primer_type eq 'chip' ) {
			# Check to make sure the user has entered a valid genome
			unless ( $genome eq 'mm9' || $genome eq 'hg19' ) {
				push (@$file_errors, "On line $line_number, the genome: $genome is not valid. It must be either mm9 or hg19");
				$valid_primer_line = 0;
			}
			# Set the genome if the genome is valid
			if ( $valid_primer_line == 1 ) {
				$self->genome = $genome;
				# If the accession contains a version number, remove it
				if ( $accession =~ /^(\w\w_\d+)\.\d+$/ ) {
					$accession = $1;
				}
				# Check to make sure that the accession entered is valid
				my $location_string = $self->accessions->{$accession};
				unless ( $location_string ) {
					push (@$file_errors, "On line $line_number, the accession: $accession is not valid. It was not found in the $genome promoters file and the chromosomal location could not be determined");
					$valid_primer_line = 0;
				}
				# Determine whether the relative locations specified in the file are valid if the accession is valid
				if ( $valid_primer_line == 1 ) {
					# Make sure that the values entered for relative positions have the required
					# information
					# The field must lead with a '+' or a '-' followed by an integer.
					# Alternative the field may be a '0'
					unless ( $left_primer_chip_location =~ /^\+\d+$|^-\d+$|^0$/ ) {
						push (@$file_errors, "On line $line_number, the left primer chip location: $left_primer_chip_location is not valid. It must lead with either a '+' or a '-' followed by an integer. Alternatively it may be a '0'");
						$valid_primer_line = 0;
					}
					unless ( $right_primer_chip_location =~ /^\+\d+$|^-\d+$|^0$/ ) {
						push (@$file_errors, "On line $line_number, the right primer chip location: $right_primer_chip_location is not valid. It must lead with either a '+' or a '-' followed by an integer. Alternatively it may be a '0'");
						$valid_primer_line = 0;
					}
					# If both of the fields contain the requisite information, test to ensure that the relative postions are vaild
					if ( $valid_primer_line == 1 ) {
						my ($chromosome, $transcriptional_start_site) = split(/\t/, $location_string);
						# Determine the maximum length of the chromosome where the accession appears
						# This will be used to determine if the relative positions given by the user
						# are valid based on the length of the chromosome
						my $chromosome_length = $self->chromosome_sizes->{$chromosome};
						my $left_primer_five_prime = $self->_extract_relative_position($transcriptional_start_site, $left_primer_chip_location);
						my $right_primer_five_prime = $self->_extract_relative_position($transcriptional_start_site, $right_primer_chip_location);
						unless ( $left_primer_five_prime >= 0 && $left_primer_five_prime <= $chromosome_length ) {
							push (@$file_errors, "On line $line_number, the left primer chip location: $left_primer_chip_location is not valid. The relative position on chromosome: $chromosome is $left_primer_five_prime, which is not a valid location.");
							$valid_primer_line = 0;
						}
						unless ( $right_primer_five_prime >= 0 && $right_primer_five_prime <= $chromosome_length ) {
							push (@$file_errors, "On line $line_number, the right primer chip location: $right_primer_chip_location is not valid. The relative position on chromosome: $chromosome is $right_primer_five_prime, which is not a valid location.");
							$valid_primer_line = 0;
						}
						if ( $valid_primer_line == 1 ) {
							push( @{$structure->{chip_primers_to_design}},
								{
									left_primer_sequence	=>	$left_primer_sequence,
									right_primer_sequence	=>	$right_primer_sequence,
									user_name				=>	$user_name,
									efficiency				=>	$efficiency,
									accession				=>	$accession,
									chromosome				=>	$chromosome,
									left_primer_five_prime	=>	$left_primer_five_prime,
									right_primer_five_prime	=>	$right_primer_five_prime,
									genome					=>	$genome,
								}
							);
						} 
					}
				}
			}
		}
		# Increase the line number iterator
		$line_number++;
	}
	return ($structure, $file_errors);
}

=head2 _extract_relative_position

This is a private subroutine that is used to extract the relative chromosomal position
based on transcriptional start site and the relative position string entered by the
user.

=cut

sub _extract_relative_position {
	my ($self, $transcriptional_start_site, $relative_position_string) = @_;
	my $relative_change;
	if ( $relative_position_string =~ /(\d+)/ ) {
		$relative_change = $1;
	}
	if ( $relative_change >= 0) {
		if ( $relative_position_string =~ /\+/ ) {
			return ($transcriptional_start_site + $relative_change);
		} elsif ( $relative_position_string =~ /-/ ) {
			return ($transcriptional_start_site - $relative_change);
		} else {
			return $transcriptional_start_site;
		}
	} else {
		return undef;
	}
}

=head2 chip_primer_search

This subroutine is called when RefSeq accessions are recognized by regular
expressions during the primer database search. This subroutine is passed
the Array Ref of accessions and returns any created or validated ChIP/Genomic
primers that are in the database.

=cut

sub chip_primer_search {
	my ($self, $c, $accessions_to_search) = @_;
	# Create Hash Ref of primer database strings for the validated and created
	# ChIP/Genomic DNA databases
	my $databases = {
		'created_primers'	=>	{
			general		=>	'Created_ChIP_Primers::ChipPrimerPairsGeneral',
			relative	=>	'Created_ChIP_Primers::ChipPrimerPairsRelativeLocation',
		},
#		'validated_primers'	=>	{
#			general		=>	'',
#			relative	=>	'',
#		}
	};
	# Create a Hash Ref to hold Array Refs of primers found in the databases
	my $found_primers = {};
	# Create an Array Ref to hold any matched location ids
	my $location_ids = [];
	# Create an result set instance of the location database
	my $chip_primers_locations_result_set = $c->model('Created_ChIP_Primers::RelativeLocation');
	foreach my $accession_to_search (@$accessions_to_search) {
		my $created_chip_primers_accession_result = $chip_primers_locations_result_set->search(
			{
				location	=>	{ 'like',  '%' . $accession_to_search . '%' },
			}
		);
		# Extract the location ID from each match
		while ( my $location_match = $created_chip_primers_accession_result->next ) {
			push (@$location_ids, $location_match->id);
		}
	}
	foreach my $primer_type ( keys %$databases ) {
		# Create a Hash Ref to hold primer pair ids for the created ChIP primers
		my $chip_primer_ids = {};
		# Create a result set for the created ChIP primers relative location database
		my $chip_primers_relative_locations_result_set = $c->model($databases->{$primer_type}{relative});
		my $chip_primers_locations_results = $chip_primers_relative_locations_result_set->search(
			{
				location_id	=>	$location_ids,
			}
		);
		while ( my $chip_primers_location_result = $chip_primers_locations_results->next ) {
			unless( defined( $chip_primer_ids->{$chip_primers_location_result->pair_id} ) ) {
				$chip_primer_ids->{$chip_primers_location_result->pair_id} = 1;
			}
		}
		# For each of the found created ChIP/genomic primer IDs, retreive all of the relative locations
		foreach my $primer_pair_id ( keys %$chip_primer_ids ) {
			# Retrieve the primer information from the general created primers table
			my $chip_primer_pairs_result_set = $c->model($databases->{$primer_type}{general});
			my $chip_primer_pair_results = $chip_primer_pairs_result_set->search(
				{
						id	=>	$primer_pair_id,
				}
			);
			while ( my $chip_primer_pair_result = $chip_primer_pair_results->next ) {
				# Create an Array Ref to hold all of the relative location ids
				my $relative_location_ids = [];
				# Fetch each relative location id from the relational database
				my $pair_id = $chip_primer_pair_result->id;
				my $relative_location_search = $chip_primers_relative_locations_result_set->search(
					{
						pair_id	=>	$pair_id
					}
				);
				while ( my $relative_location_search_result = $relative_location_search->next ) {
					push(@$relative_location_ids, $relative_location_search_result->location_id);
				}
				# Fetch the relative locations string, parse them and place the strings in the original hash
				my $raw_relative_locations_search_results = $chip_primers_locations_result_set->search(
					{
						id	=>	$relative_location_ids,
					}
				);
				while ( my $raw_relative_locations_search_result = $raw_relative_locations_search_results->next ) {
					push(@{$chip_primer_pair_result->{relative_locations}}, $raw_relative_locations_search_result->location);
				}
				push (@{$found_primers->{$primer_type}}, $chip_primer_pair_result);
			}
		}
	}
	return $found_primers;
}

=head2 cdna_primer_search

This subroutine is called by the Controller when potential RefSeq mRNAs are
found in the search string by regular expression searches. This subroutine
searches both the validated and created cDNA primer databases to find primers
that correspond to the accessions found in the search string. All found primers
are returned to the controller to be returned to the user.

=cut

sub cdna_primer_search {
	my ($self, $c, $accessions_to_search) = @_;
	# Create a Hash Ref to hold the database strings for each type of primer
	my $databases = {
		created_primers		=>	'Created_Primers::Primer',
#		validated_primers	=>	'',
	};
	# Create a Hash Ref to hold found primers
	my $found_primers = {};
	foreach my $primer_type (keys %$databases) {
		my $mrna_result_set = $c->model($databases->{$primer_type});
		my $mrna_accession_search_results = $mrna_result_set->search(
			{
				accession	=>	$accessions_to_search
			}
		);
		while ( my $mrna_accession_search_result = $mrna_accession_search_results->next ) {
			push(@{$found_primers->{$primer_type}}, $mrna_accession_search_result);
		}
		# Check to see if the user has entered an mRNA root by extracting the full accession
		# from the gene2accession database and searching that as well
		my $accession_root_search_results = $c->model('Valid_mRNA::Gene2accession')->search(
			{
				mrna_root	=>	$accessions_to_search
			}
		);
		while ( my $accession_root_search_result = $accession_root_search_results->next ) {
			my $root_search_results = $mrna_result_set->search(
				{
					accession	=>	$accession_root_search_result->mrna
				}
			);
			while ( my $root_search_result = $root_search_results->next ) {
				push(@{$found_primers->{$primer_type}}, $root_search_result);
			}
		}
	}
	return $found_primers;
}

__PACKAGE__->meta->make_immutable;

1;
