package FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3;
use Moose::Role;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Model::PrimerDesign::Primer3;
use Data::Dumper;

=head1 NAME

FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3 - Catalyst Model

=head1 DESCRIPTION

This Moose::Role exports the functions for the creation of primers for cDNA
sequences and returns a Hash Ref of the information about each primer pair made
for the given cDNA sequence.

=head1 AUTHOR

Jason R Dobson L<foxprimer@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

=head2 make_primer3_primers

This subroutine creates a FoxPrimer::Model::Updated_Primer3_Run object and runs
primer3 for the cDNA sequence in the file provided by the user.  Primers and
their cognate information is returned in a Hash Ref. If no primers are designed,
an error message is returned along with an empty Hash Ref. The final variable
returned in the number of primers designed by Primer3.

This subroutine is passed the following arguments:

    1. A valid primer3 product size string
    2. The path to a primer3 mispriming library file
    3. A cDNA sequence as a string

and returns an Array Ref of created primers, an Array Ref of error messages and
an integer value for the number of primers created.

=cut

sub make_primer3_primers {
    my $self = shift;
    my $product_size = shift;
    my $mispriming_file = shift;
    my $cdna_seq = shift;

    # Pre-declare a Hash Ref to hold the primers created.
    my $created_primers = {};

    # Pre-declare a String to hold any error messages
    my $error_messages = '';

    # Extract the cDNA sequence by running the 'cdna_sequence' subroutine
#    my $cdna_seq = $self->cdna_sequence;

#    # Create a FoxPrimer::Model::Updated_Primer3_Run object
#    my $primer3 = FoxPrimer::Model::Updated_Primer3_Run->new(
#        -seq        =>  $cdna_seq,
#        -outfile    =>  "$FindBin::Bin/../tmp/primer3/temp.out",
#        -path       =>  $self->primer3_path
#    );
    # Create a FoxPrimer::Model::PrimerDesign::Primer3 object
    my $primer3 = FoxPrimer::Model::PrimerDesign::Primer3->new(
        SEQUENCE_TEMPLATE                       =>  $cdna_seq,
        PRIMER_TASK                             =>  'generic',
        PRIMER_PRODUCT_SIZE_RANGE               =>  $product_size,
        PRIMER_THERMODYNAMIC_PARAMETERS_PATH    =>  "$FindBin::Bin/../root/static/primer3_files/primer3_config/",
        PRIMER_MISPRIMING_LIBRARY               =>  $mispriming_file
    );

#    # Add the mispriming library, number to make, and a product size range
#    # to the FoxPrimer::Model::Updated_Primer3_Run object.
#    $primer3->add_targets(
#        'PRIMER_MISPRIMING_LIBRARY'     =>  $self->mispriming_file,
#        'PRIMER_NUM_RETURN'             =>  500,
#        'PRIMER_PRODUCT_SIZE_RANGE'     =>  $self->product_size,
#    );

#    # Run primer3 and return the results as a Hash Ref
#    my $results = $primer3->run;

    # Copy the 'creation_results_stone' object into a local variable
    my $results = $primer3->creation_results_stone;

    my $num_returned = $results->get('PRIMER_PAIR_NUM_RETURNED')->{'.name'};

    # Make sure that primer3 was able to create primers under the
    # conditions specified by the user. If not return an error message.
    if ( $results->get('PRIMER_PAIR_NUM_RETURNED') > 0 ) {

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

        $error_messages = "Primer3 was unable to design primers for " . 
        "the cDNA sequence under the conditions you have specified.";

        return ($created_primers, $error_messages, 0);
    }
}

1;
