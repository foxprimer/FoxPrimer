package FoxPrimer::Model::PrimerDesign::chipPrimerDesign;
use Moose;
use Carp;
use autodie;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa;
use FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO;
use FoxPrimer::Model::PeaksToGenes;
use Data::Dumper;

with 'FoxPrimer::Model::Primer_Database';
with 'FoxPrimer::Model::PrimerDesign::chipPrimerDesign::Primer3';

=head1 NAME

FoxPrimer::Model::PrimerDesign::chipPrimerDesign - Catalyst Model

=head1 DESCRIPTION

This is the main sub-controller, which is used by FoxPrimer to design ChIP
primers.

=head1 AUTHOR

Jason R Dobson L<foxprimer@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

=head2 product_size

This Moose object holds the pre-validated string for the product size.

=cut

has product_size	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 motif

This Moose object holds the pre-validated string for the motif the user
would like to search for in their genomic intervals.

=cut

has motif	=>	(
	is			=>	'ro',
	isa			=>	'Str',
    predicate   =>  'has_motif',
);

=head2 genome

This Moose object holds the string for the pre-validated genome for ChIP
primer design.

=cut

has genome	=>	(
	is			=>	'ro',
	isa			=>	'Str',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must specify a genome to create ChIP primers for.\n\n";
    },
);

=head2 ucsc_schema

This Moose attribute uses FoxPrimer::Model::Primer_Database to dynamically
create a DBIx::Schema for connection to the UCSC MySQL genome browser.

=cut

has ucsc_schema =>  (
    is          =>  'ro',
    isa         =>  'FoxPrimer::Model::UCSC',
    predicate   =>  'has_ucsc_schema',
    writer      =>  '_set_ucsc_schema',
);

before  'ucsc_schema'   =>  sub {
    my $self = shift;
    unless ($self->has_ucsc_schema) {
        $self->_set_ucsc_schema($self->_get_ucsc_schema);
    }
};

=head2 _get_ucsc_schema

This private subroutine is called dynamically to get the UCSC::Schema object for
the user-defined genome.

=cut

sub _get_ucsc_schema    {
    my $self = shift;
    my $ucsc_schema = $self->define_ucsc_schema($self->genome);
    return $ucsc_schema;
}

=head2 chromosome_sizes

This Moose attribute is dynamically defined based on the user-defined genome and
contains a Hash Ref of chromosome names as keys and integer lengths as values.

=cut

has chromosome_sizes    =>  (
    is          =>  'ro',
    isa         =>  'HashRef',
    predicate   =>  'has_chromosome_sizes',
    writer      =>  '_set_chromosome_sizes',
);

before  'chromosome_sizes'  =>  sub {
    my $self = shift;
    unless ( $self->has_chromosome_sizes ) {
        $self->_set_chromosome_sizes($self->_get_chromosome_sizes);
    }
};

=head2 _get_chromosome_sizes

This private subroutine is run dynamically to fetch the chromosome sizes from
the UCSC MySQL server.

=cut

sub _get_chromosome_sizes   {
    my $self = shift;

    # Get the chromosome sizes from UCSC
    my $raw_chrom_sizes = $self->ucsc_schema->storage->dbh_do(
        sub {
            my ($storage, $dbh, @args) = @_;
            $dbh->selectall_hashref("SELECT chrom, size FROM chromInfo",
                ["chrom"]);
        },
    );

    # Pre-declare a Hash Ref to hold the final information for the chromosome sizes
    my $chrom_sizes = {};

    # Parse the chromosome sizes file into an easier to use form
    foreach my $chromosome (keys %$raw_chrom_sizes) {
        $chrom_sizes->{$chromosome} = $raw_chrom_sizes->{$chromosome}{size};
    }

    return $chrom_sizes;
}

=head2 bed_file

This Moose attribute holds the path to the BED-format file that contains the
coordinates within which primers will be designed.

=cut

has bed_file    =>  (
    is          =>  'ro',
    isa         =>  'File::Temp',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must define a File::Temp object for the BED file that " .
        "contains the coordinates where primers will be designed.\n\n";
    },
);

=head2 _max_bed_lines

This private Moose object is to be controlled by the administrator based on
their server's capabilities. This controls how many lines of the BED file
uploaded by the user that will be read in for ChIP primer design. By default
this value is set to 10.

=cut

has _max_bed_lines  =>  (
    is          =>  'ro',
    isa         =>  'Int',
    default     =>  10,
    required    =>  1,
    lazy        =>  1,
    reader      =>  'max_bed_lines',
    writer      =>  '_set_max_bed_lines',
);

=head2 mispriming_file

This Moose attribute hold the path to the mispriming file that will be used for
primer design.

=cut

has mispriming_file	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	required	=>	1,
	lazy		=>	1,
	default		=>	sub {
        croak "\n\nYou must set a mispriming file.\n\n";
	},
);

=head2 bed_coordinates

This Moose attribute holds an Array Ref of valid BED-format coordinates. This
attribute is populated dynamically from the BED file defined by the user.

=cut

has bed_coordinates =>  (
    is          =>  'ro',
    isa         =>  'ArrayRef',
    predicate   =>  'has_bed_coordinates',
    writer      =>  '_set_bed_coordinates',
);

before 'bed_coordinates'    =>  sub {
    my $self = shift;
    unless ( $self->has_bed_coordinates && $self->has_bed_file_errors ) {
        my ($bed_coordinates, $bed_file_errors) = $self->_check_bed_file;
        $self->_set_bed_coordinates($bed_coordinates);
        $self->_set_bed_file_errors($bed_file_errors);
    }
};

=head2 bed_file_errors

This Moose attribute holds any errors found in the user-defined BED file. This
attribute is dynamically defined.

=cut

has bed_file_errors =>  (
    is          =>  'ro',
    isa         =>  'ArrayRef',
    predicate   =>  'has_bed_file_errors',
    writer      =>  '_set_bed_file_errors'
);

before 'bed_file_errors'    =>  sub {
    my $self = shift;
    unless ( $self->has_bed_coordinates && $self->has_bed_file_errors ) {
        my ($bed_coordinates, $bed_file_errors) = $self->_check_bed_file;
        $self->_set_bed_coordinates($bed_coordinates);
        $self->_set_bed_file_errors($bed_file_errors);
    }
};

=head2 _check_bed_file

This private subroutine is run dynamically to iterate through the user-defined
BED file. This subroutine makes sure that the relevant fields of the BED file
are valid and returns these coordinates as an Array Ref and any errors found as
an Array Ref.

=cut

sub _check_bed_file {
    my $self = shift;

    # Pre-declare an Array Ref to hold the BED-format coordinates
    my $coordinates = [];

    # Pre-declare an Array Ref to hold any errors found in the BED file.
    my $errors = [];

    # Pre-declare a line number to return useful error messages
    my $line_number = 0;

    # Open the user-defined BED file, iterate through the lines, check each line
    # and add the line to coordinates or information about the line to errors as
    # appropriate.
    open my $bed_file, '<', $self->bed_file;
    while(<$bed_file>) {
        my $line = $_;
        chomp($line);
        my @bed_fields = split(/\t/, $line);

        # Increase the line number
        $line_number++;

        # Check to make sure the current chromosome is valid for the
        # user-defined genome
        if ( $self->chromosome_sizes->{$bed_fields[0]} ) {

            # Check to make sure start and stop fields are positive integer
            # values
            if ( ($bed_fields[1] =~ /^\d+$/) && ($bed_fields[1] >= 1) && 
                ($bed_fields[2] =~ /^\d+$/) && ($bed_fields[2] >= 1) ) {

                # Check to make sure the stop coordinate is larger than the
                # start coordinate
                if ( $bed_fields[2] > $bed_fields[1] ) {

                    # Check to make sure that both start and stop coordinates
                    # are valid for the current chromosome length
                    if ( ($bed_fields[1] <=
                            $self->chromosome_sizes->{$bed_fields[0]}) &&
                        ( $bed_fields[2] <=
                            $self->chromosome_sizes->{$bed_fields[0]}) ) {

                        # The coordinates are valid, add then to the coordinates
                        # Array Ref
                        push(@{$coordinates}, 
                            {
                                chromosome  =>  $bed_fields[0],
                                start       =>  $bed_fields[1],
                                stop        =>  $bed_fields[2],
                            }
                        );
                    } else {

                        # Add an error message to the errors Array Ref
                        push(@{$errors}, "The coordinates $bed_fields[1] and " .
                            "$bed_fields[2] are not valid for the chromosome " .
                            "$bed_fields[0] in the $self->genome genome."
                        );
                    }
                } else {

                    # Add an error message to the errors Array Ref
                    push(@{$errors}, "The stop coordinate $bed_fields[2] " .
                        "must be larger than the start coordiante " .
                        "$bed_fields[1] on line $line_number."
                    );
                }
            } else {

                # Add an error message to the errors Array Ref
                push(@{$errors}, "The start and stop fields on line: " .
                   "$line_number are not positive integers."
               );
            }
        } else {

            # Add an error message to the errors Array Ref
            push(@{$errors}, "The chromosome $bed_fields[0] is not " .
                "valid for the $self->genome genome on line $line_number"
                . " of your file."
            );
        }
    }
    close $bed_file;

    # See if the admin-defined limit on the number of locations to make qPCR
    # primers for has been reached
    if ( $line_number > $self->max_bed_lines ) {
        push ( @{$errors}, "The maximum number of lines $self->max_bed_lines " .
            "has been reached. Please use less intervals for primer design.");
    }

    return ($coordinates, $errors);
}

=head2 extended_bed_coordinates

This Moose attribute is dynamically defined based on the product size string
defined by the user and the length of each interval from the valid BED-format
file uploaded by the user. This attribute holds the extended coordinates in
Array Ref format, where each entry in the Array Ref is a BED-format line.

=cut

has extended_bed_coordinates    =>  (
    is          =>  'ro',
    isa         =>  'ArrayRef',
    predicate   =>  'has_extended_bed_coordinates',
    writer      =>  '_set_extended_bed_coordinates',
);

before  'extended_bed_coordinates'  =>  sub {
    my $self = shift;
    unless($self->has_extended_bed_coordinates) {
        $self->_set_extended_bed_coordinates($self->_get_extended_bed_coordinates);
    }
};

=head2 _get_extended_bed_coordinates

This subroutine extends the coordinates based on the product_size max product
length.

=cut

sub _get_extended_bed_coordinates {
    my $self = shift;

	# Pre-declare an Array Ref to hold the extended coordinates.
	my $extended_coordinates = [];

	# Extract the min and max product sizes from the product size string.
	my ($min_size, $max_size) = split(/-/, $self->product_size);

    # Iterate through the BED-format coordinates defined in bed_coordinates
    foreach my $coordinates ( @{$self->bed_coordinates} ) {

        # Copy the coordinates to local values
        my $chr = $coordinates->{chromosome};
        my $start = $coordinates->{start};
        my $stop = $coordinates->{stop};

        # Calculate the interval length
        my $interval_length = $stop - $start;

        # Make sure the length of the interval is more than twice the length of
        # the max primer product size
        if ( $interval_length < (2 * $max_size) ) {

            # Extend the coordinates and make sure they are valid
            # coordinates for the given chromosome on the user-defined
            # genome
            # 
            # Calculate the difference between the interval length and the
            # desired interval length
            my $interval_diff = (2 * $max_size) - $interval_length;

            # Calculate how many bases the start and stop need to be extended in
            # the 5' and 3' directions, respectively.
            my $extension_length = int(($interval_diff / 2) + 0.5);

            # Calculate the extended start and stop. Make sure they are valid
            # for the current chromosome
            my $extended_start = $start - $interval_diff;
            my $extended_stop = $stop + $interval_diff;

            # Make sure the extended start is greater than zero. If not,
            # calculate the negative difference and add it to the extended_stop
            if ( $extended_start <= 0 ) {
                $extended_stop += ( 1 - $extended_start );
            }

            # Make sure the extended stop is less than or equal to the length of
            # the current chromosome. If not, calculate the positive difference
            # and subtract it from the extended_start
            if ( $extended_stop > $self->chromosome_sizes->{$chr} ) {
                $extended_start -= ($extended_stop -
                    $self->chromosome_sizes->{$chr}
                );
            }

            # Add the extended coordinates in BED format to extended_coordinates 
            push(@{$extended_coordinates},
                {
                    chromosome      =>  $chr, 
                    start           =>  $extended_start, 
                    stop            =>  $extended_stop,
                    target_start    =>  $start,
                    target_stop     =>  $stop,
                }
            );
        } else {

            # Add the original coordinates to the extended_coordinates Array Ref
            push(@{$extended_coordinates}, $coordinates);
        }
    }

    return $extended_coordinates;
}

=head2 design_primers

This subroutine is the mini-controller, which controls the workflow and business
logic for designing ChIP primers.

=cut

sub design_primers {
	my $self = shift;

	# Pre-declare an Array Ref to hold the designed primers.
	my $designed_primers = [];

	# Pre-declare an Array Ref to hold error messages for primer design
	# errors.
	my $design_errors = [];

    # Create an instance of
    # FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa and run the
    # 'create_temp_fasta' subroutine to get an Array Ref of File::Temp objects
    # of FASTA-format files
    my $twobit = FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa->new(
        genome      =>  $self->genome,
        coordinates =>  $self->extended_bed_coordinates,
    );

    my $fasta_files = $twobit->create_temp_fasta;

    # Test to see if a motif was defined by the user
    if ( $self->motif && $self->motif ne 'No Motif' ) {

        # Pre-declare an Array Ref to hold the matched motif coordinates
        my $motif_coordinates_array = [];

        # Iterate through the FASTA files
        foreach my $fasta_file ( @{$fasta_files} ) {

            # Create an instance of
            # FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO and run the
            # 'find_motifs' subroutine to return the coordinates of matched
            # motifs
            my $fimo = FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO->new(
                fasta_file  =>  $fasta_file,
                motif       =>  $self->motif,
            );
            my $motif_coordinates = $fimo->find_motifs;

            # If motif coordinates were found, add them to the
            # motif_coordinates_array, if not add a message to design_errors
            if ( $motif_coordinates && ( scalar (@{$motif_coordinates}) >= 1) ) {
                push( @{$motif_coordinates_array}, @{$motif_coordinates} );
            } else {
                push(@{$design_errors}, "Unable to find a match for the motif " .
                    $self->motif . " within the coordinates " . 
                    $fimo->fasta_coordinates->{start} . 'bp to ' .
                    $fimo->fasta_coordinates->{stop} . "bp on " .
                    $fimo->fasta_coordinates->{chromosome} . '.'
                );
            }
        }

        # If there were matched motifs found, replace the bed_coordinates and
        # extended_bed_coordinates Moose attributes, otherwise end the
        # subroutine.
        if ( $motif_coordinates_array && ( scalar (@{$motif_coordinates_array})
                >= 1)) {
            $self->_set_bed_coordinates($motif_coordinates_array);
            $self->_set_extended_bed_coordinates($self->_get_extended_bed_coordinates);

            # Create a new instance of
            # FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa to
            # make FASTA files for the newly extended FASTA files centered
            # around the matched motifs.
            my $motif_twobit =
            FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa->new(
                genome      =>  $self->genome,
                coordinates =>  $self->extended_bed_coordinates,
            );

            # Replace the files in fasta_files with the new File::Temp
            # FASTA-format objects
            $fasta_files = $motif_twobit->create_temp_fasta;
        } else {
            return ( $designed_primers, $design_errors );
        }
    } 

    # At this point, there is an Array Ref of primer coordinates and a
    # corresponding FASTA-format File::Temp object in
    # $self->extended_bed_coordinates and $fast_files. Run the 'create_primers'
    # subroutine consumed from
    # FoxPrimer::Model::PrimerDesign::chipPrimerDesign::Primer3
    for ( my $i = 0; $i < @{$self->extended_bed_coordinates}; $i++ ) {
        my ($current_results, $current_errors, $current_number_created) = $self->create_primers(
            $self->extended_bed_coordinates->[$i],
            $fasta_files->[$i],
            $self->product_size,
            $self->mispriming_file,
        );

        # If primers were not designed, add the error messages to the Array Ref
        # of error messages
        if ( $current_errors && ( scalar @{$current_errors} >= 1 ) ) {
            push(@{$design_errors}, join("<br>", @{$current_errors}));
        } else {

            # Map the primers to the genome by creating an instance of
            # FoxPrimer::Model::PeaksToGenes
            my $ptg = FoxPrimer::Model::PeaksToGenes->new(
                genome              =>  $self->genome,
                primers             =>  $current_results,
                chromosome_sizes    =>  $self->chromosome_sizes,
                target_coordinates  =>  $self->extended_bed_coordinates->[$i],
            );

            # Run the 'annotate_primer_pairs' subroutine to return a Hash Ref of
            # relative genomic locations indexed by each primer pair designed.
            my $primer_pair_genomic_context = $ptg->annotate_primer_pairs;

            # Add the primer information to the designed_primers Array Ref in
            # Hash Ref format.
            foreach my $primer_pair ( keys %{$primer_pair_genomic_context} ) {

                # Extract the five prime position and length of each primer
                my ($left_five_prime_pos, $left_length) = 
                split(/,/, $current_results->{$primer_pair}{'Left Primer Coordinates'});
                my ($right_five_prime_pos, $right_length) = 
                split(/,/, $current_results->{$primer_pair}{'Right Primer Coordinates'});

                # Calculate the exact genomic position of the primers
                my $left_gen_pos = ($left_five_prime_pos - 1) +
                $self->extended_bed_coordinates->[$i]{start};
                my $right_gen_pos = ($right_five_prime_pos - 1) +
                $self->extended_bed_coordinates->[$i]{start};

                # Add the values to designed_primers
                push(@{$designed_primers},
                    {
                        left_primer_sequence        =>  $current_results->{$primer_pair}{'Left Primer Sequence'},
                        right_primer_sequence       =>  $current_results->{$primer_pair}{'Right Primer Sequence'},
                        chromosome                  =>  $self->extended_bed_coordinates->[$i]{chromosome},
                        genome                      =>  $self->genome,
                        left_primer_five_prime      =>  $left_gen_pos,
                        right_primer_five_prime     =>  $right_gen_pos,
                        left_primer_three_prime     =>  $left_gen_pos + ($left_length - 1),
                        right_primer_three_prime    =>  $right_gen_pos - ($right_length - 1),
                        product_size                =>  $current_results->{$primer_pair}{'Product Size'},
                        left_primer_tm              =>  $current_results->{$primer_pair}{'Left Primer Tm'},
                        right_primer_tm             =>  $current_results->{$primer_pair}{'Right Primer Tm'},
                        primer_pair_penalty         =>  $current_results->{$primer_pair}{'Product Penalty'},
                        relative_locations          =>  join('<br>', @{$primer_pair_genomic_context->{$primer_pair}}),
                    }
                );
            }
        }
    }

    return ($designed_primers, $design_errors);
}

__PACKAGE__->meta->make_immutable;

1;
