package FoxPrimer::Model::PrimerDesign::chipPrimerDesign::Primer3;
use Moose::Role;
use Carp;
use namespace::autoclean;
use autodie;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Model::PrimerDesign::Primer3;
use Data::Dumper;

=head1 NAME

FoxPrimer::Model::PrimerDesign::chipPrimerDesign::Primer3 - Catalyst Model

=head1 DESCRIPTION

This Module designs primers for ChIP-qPCR.

=head1 AUTHOR

Jason R Dobson L<foxprimer@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 create_primers

This subroutine will make a call to Primer3 and design primers and returns
an Array Ref of Hash Refs of primer information. This subroutine takes the following arguments:

    1. A Hash Ref of primer information (genomic targets)
    2. A File::Temp object corresponding to the FASTA files of the target
       sequenes.
    3. The pre-validated product size string.
    4. The path to the appropriate mispriming file.

=cut

sub create_primers {
    my $self = shift;
    my $target_coordinates = shift;
    my $fasta_file = shift;
    my $product_size = shift;
    my $mispriming_file = shift;

    # Pre-declare a Hash Ref to hold the primers created.
    my $created_primers = {};

    # Pre-declare an Array Ref to hold any error messages
    my $error_messages = [];

    # Run the _get_template_seq subroutine to extract the sequence from the
    # user-defined FASTA file
    my $template_seq = $self->_get_template_seq($fasta_file);

    # Run the _get_sequence_target subroutine to extract the primer3-formatted
    # string to define the location to target for primer design
    my $target_seq = $self->_get_sequence_target($target_coordinates);

    # Create a FoxPrimer::Model::PrimerDesign::Primer3 object, depending on
    # whether the user is adding extended coordinates, define the 
    my $primer3 = FoxPrimer::Model::PrimerDesign::Primer3->new(
        SEQUENCE_TEMPLATE                       =>  $template_seq,
        PRIMER_TASK                             =>  'generic',
        PRIMER_PRODUCT_SIZE_RANGE               =>  $product_size,
        PRIMER_THERMODYNAMIC_PARAMETERS_PATH    =>  "$FindBin::Bin/../root/static/primer3_files/primer3_config/",
        PRIMER_MISPRIMING_LIBRARY               =>  $mispriming_file,
        PRIMER_EXPLAIN_FLAG                     =>  1,
        SEQUENCE_TARGET                         =>  $target_seq,
        PRIMER_NUM_RETURN                       =>  10,
    );

    # Copy the 'creation_results_stone' object into a local variable
    my $results = $primer3->creation_results_stone;

    # Make sure that primer3 was able to create primers under the
    # conditions specified by the user. If not return an error message.
    if ( $results->get('PRIMER_PAIR_NUM_RETURNED') > 0 ) {

        my $num_returned = $results->get('PRIMER_PAIR_NUM_RETURNED')->{'.name'};

        # Iterate through the primers have have been designed and extract
        # their coordinates.
        for (my $i = 0; $i < $num_returned; $i++) {

            # Store the primer information in the created_primers Hash Ref
            $created_primers->{'Primer Pair ' . $i}{ 'Left Primer Coordinates'}
            = $results->get("PRIMER_LEFT_$i")->{'.name'};

            $created_primers->{'Primer Pair ' . $i}{ 'Right Primer Coordinates'}
            = $results->get("PRIMER_RIGHT_$i")->{'.name'};

            $created_primers->{'Primer Pair ' . $i}{'Left Primer Sequence'} =
            $results->get('PRIMER_LEFT_' . $i .  '_SEQUENCE')->{'.name'};

            $created_primers->{'Primer Pair ' . $i}{ 'Right Primer Sequence'} =
            $results->get('PRIMER_RIGHT_' . $i . '_SEQUENCE')->{'.name'};

            $created_primers->{'Primer Pair ' . $i}{ 'Left Primer Tm'} =
            $results->get('PRIMER_LEFT_' . $i . '_TM')->{'.name'};

            $created_primers->{'Primer Pair ' . $i}{ 'Right Primer Tm'} =
            $results->get('PRIMER_RIGHT_' . $i . '_TM')->{'.name'};

            $created_primers->{'Primer Pair ' . $i}{ 'Product Size'} =
            $results->get('PRIMER_PAIR_' . $i . '_PRODUCT_SIZE')->{'.name'};

            $created_primers->{'Primer Pair ' . $i}{ 'Product Penalty'} =
            $results->get('PRIMER_PAIR_' . $i . '_PENALTY')->{'.name'};
        }


        return ($created_primers, $error_messages, $num_returned);
    } else {

        push(@{$error_messages},
            'Could not design primers for the target coordinates: ' .
            $target_coordinates->{chromosome} . ':' .
            $target_coordinates->{start} . '-' . $target_coordinates->{stop},
            'All pairs considered: ' .
            $results->get('PRIMER_PAIR_EXPLAIN')->{'.name'},
            'Left Primers considered: ' .
            $results->get('PRIMER_LEFT_EXPLAIN')->{'.name'},
            'Right Primers considered: ' .
            $results->get('PRIMER_RIGHT_EXPLAIN')->{'.name'},
        );

        return ($created_primers, $error_messages, 0);
    }
}

#sub create_primers {
#	my $self = shift;
#
#	# Pre-declare a Array Ref to hold the primers created.
#	my $created_primers = [];
#
#	# Pre-declare a String to hold any error messages.
#	my $error_messages = '';
#
#	# Extract the cDNA sequence by running the 'cdna_sequence' subroutine
#	my $cdna_seq = $self->cdna_sequence;
#
#	# Create a FoxPrimer::Model::Updated_Primer3_Run object
#	my $primer3 = FoxPrimer::Model::Updated_Primer3_Run->new(
#		-seq		=>	$cdna_seq,
#		-outfile	=>	"$FindBin::Bin/../tmp/primer3/temp.out",
#		-path		=>	$self->primer3_path
#	);
#
#	# Check to see if a target has been defined to Primer3 to design
#	# primers around. If one has add it to Primer3.
#	if ( $self->target ne 'None' ) {
#		# Create a string for the relative coordiantes to be passed to Primer3
#		$primer3->add_targets(
#			'PRIMER_MISPRIMING_LIBRARY'		=>	$self->mispriming_file,
#			'PRIMER_NUM_RETURN'				=>	5,
#			'PRIMER_PRODUCT_SIZE_RANGE'		=>	$self->product_size,
#			'SEQUENCE_TARGET'				=>	$self->target,
#		);
#	} else {
#		$primer3->add_targets(
#			'PRIMER_MISPRIMING_LIBRARY'		=>	$self->mispriming_file,
#			'PRIMER_NUM_RETURN'				=>	5,
#			'PRIMER_PRODUCT_SIZE_RANGE'		=>	$self->product_size,
#		);
#	}
#
#	# Run primer3 and return the results as a Hash Ref
#	my $results = $primer3->run;
#
#	# Make sure that primer3 was able to create primers under the
#	# conditions specified by the user. If not return an error message.
#	if ( $results->number_of_results > 0 ) {
#
#		# Iterate through the primer results. Mapping their location back
#		# to full genomic coordinates.
#		for ( my $i = 0; $i < $results->number_of_results; $i++ ) {
#			
#			# Store the primer results in a local Hash Ref.
#			my $primer_result = $results->primer_results($i);
#
#			# Pre-declare a local Hash Ref for the primer information.
#			my $primer_info = {};
#
#			# Pre-declare scalar variables for the relative start positions
#			# of the left and right primers.
#			my ($left_primer_temp_start, $right_primer_temp_start);
#
#			# Split the left and right primer coordinates strings, storing
#			# the relative start positions in the local variables, and the
#			# lengths in the created_primers Hash Ref.
#			($left_primer_temp_start, $primer_info->{left_primer_length}) =
#			split(/,/, $primer_result->{PRIMER_LEFT});
#			($right_primer_temp_start, $primer_info->{right_primer_length})
#			= split(/,/, $primer_result->{PRIMER_RIGHT});
#
#			# Calculate and store the 5'- and 3'-positions of the left and
#			# right primers.
#			$primer_info->{left_primer_5prime} =
#			$self->start + ($left_primer_temp_start - 1);
#
#			$primer_info->{left_primer_3prime} =
#			$primer_info->{left_primer_5prime} +
#			$primer_info->{left_primer_length};
#
#			$primer_info->{right_primer_5prime} =
#			$self->start + ($right_primer_temp_start - 1);
#
#			$primer_info->{right_primer_3prime} =
#			$primer_info->{right_primer_5prime} -
#			$primer_info->{left_primer_length};
#
#			# Store the primer sequences
#			$primer_info->{left_primer_sequence} =
#			$primer_result->{PRIMER_LEFT_SEQUENCE};
#			$primer_info->{right_primer_sequence}
#			= $primer_result->{PRIMER_RIGHT_SEQUENCE};
#
#			# Store the primer Tms
#			$primer_info->{left_primer_tm} =
#			$primer_result->{PRIMER_LEFT_TM};
#			$primer_info->{right_primer_tm} =
#			$primer_result->{PRIMER_RIGHT_TM};
#
#			# Store the product size, product penalty, chromosome and
#			# genome
#			$primer_info->{product_size} =
#			$primer_result->{PRIMER_PAIR_PRODUCT_SIZE};
#			$primer_info->{product_penalty} =
#			$primer_result->{PRIMER_PAIR_PENALTY};
#			$primer_info->{chromosome} = $self->chromosome;
#			$primer_info->{genome} = $self->genome;
#
#			# Add the primer_info Hash Ref to the created_primers Array
#			# Ref.
#			push(@$created_primers, $primer_info);
#		}
#
#		return ($created_primers, $error_messages);
#	} else {
#
#		$error_messages = "Primer3 was unable to design primers for " . 
#		"the sequence: " . $self->chromosome . ':' . $self->start . '-' .
#		$self->end . " under the conditions you have specified.";
#
#		return ($created_primers, $error_messages);
#	}
#}

=head2 _get_template_seq

This private subroutine is passed a path to the FASTA-format file and returns a
string of the template sequence.

=cut

sub _get_template_seq   {
    my $self = shift;
    my $file = shift;

    # Pre-declare a scalar to hold the string of FASTA sequence
    my $template = '';

    # Open the file, and extract the sequence
    open my $fh, "<", $file;
    while(<$fh>) {
        my $line = $_;
        chomp($line);
        
        # Skip the header line
        unless ( $line =~ /^>/ ) {

            # Add to template 
            if ( $line ) {
                if ( $template ) {
                    $template .= $line;
                } else {
                    $template = $line;
                }
            }
        }
    }

    return $template;
}

=head2 _get_sequence_target

This private subroutine is passed a Hash Ref of sequence coordinate targets and
if there is target coordinates, a string will be created for primer3.

=cut

sub _get_sequence_target    {
    my $self = shift;
    my $coordinate_hash = shift;

    # Pre-declare a string to hold the target string
    my $target_string = '';

    # If the coordinate_hash has they keys 'target_start' and 'target_stop',
    # create a target string, otherwise just return an empty string.
    if ( $coordinate_hash->{target_start} && $coordinate_hash->{target_stop} ) {
        $target_string = join('', 
            ($coordinate_hash->{target_start} + 1) - $coordinate_hash->{start},
            ',',
            (
                ($coordinate_hash->{target_stop} + 1) -
                $coordinate_hash->{target_start}
            ),
        );
    }

    return $target_string;
}

1;
