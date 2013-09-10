package FoxPrimer::Model::PeaksToGenes::BedTools;
use Moose::Role;
use Carp;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Which;
use IPC::Run3;
use File::Temp;
use autodie;
use List::Util qw(min);

with 'FoxPrimer::Model::PeaksToGenes::FileStructure';

=head1 NAME

FoxPrimer::Model::PeaksToGenes::BedTools

=cut

=head1 DESCRIPTION

This Moose role provides the functions to determine which genes the primers
created are close to.

=cut

=head1 AUTHOR

Jason R Dobson, L<foxprimer@gmail.com>

=cut

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

=head2 intersect_bed_path

This Moose attribute holds the path to intersectBed.

=cut

has intersect_bed_path  =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_intersect_bed_path',
    writer      =>  '_set_intersect_bed_path',
);

before  'intersect_bed_path'    =>  sub {
    my $self = shift;
    unless($self->has_intersect_bed_path) {
        $self->_set_intersect_bed_path($self->_get_intersect_bed_path);
    }
};

=head2 _get_intersect_bed_path

This private subroutine is called dynamically to return the path to
intersectBed. If intersectBed is not found in the user's $PATH, the program will
die.

=cut

sub _get_intersect_bed_path {
    my $self = shift;
    my $intersect_bed_path = which('intersectBed');
    if ( $intersect_bed_path ) {
        return $intersect_bed_path;
    } else {
        croak "\n\nintersectBed was not found in the \$PATH.\n\n";
    }
}

=head2 primers_to_bed

This subroutine takes a Hash Ref of designed primers and a Hash Ref of target
sequence coordinates as arguments and returns a File::Temp object that has the
primer coordinates written to file in BED-format.

=cut

sub primers_to_bed  {
    my $self = shift;
    my $primers_hash = shift;
    my $target_coordinates = shift;

    # Pre-declare an Array Ref to hold the primers in BED-format.
    my $bed_format_primers = [];

    # Iterate through the primers, calculate the coordinates, and store the
    # coordinates in BED-format with the fourth column being the primer pair
    # number
    foreach my $primer ( keys %{$primers_hash} ) {

        # Extract the 5' and 3' coordinates of the primer product
        my ($five_prime, $five_prime_length) = split(/,/,
            $primers_hash->{$primer}{'Left Primer Coordinates'}
        );
        my ($three_prime, $three_prime_length) = split(/,/,
            $primers_hash->{$primer}{'Right Primer Coordinates'}
        );

        # Add the coordinates to the bed_format_primers Array Ref
        push(@{$bed_format_primers},
            join("\t",
                $target_coordinates->{chromosome},
                ($target_coordinates->{start} + ($five_prime - 1)),
                ($target_coordinates->{start} + ($three_prime - 1)),
                $primer
            )
        );
    }

    # Create File::Temp objects for the unsorted and sorted BED-format primer
    # files.
    my $unsorted_primers = File::Temp->new();
    my $sorted_primers = File::Temp->new();

    # Write the primer coordinates to the unsorted file
    open my $unsorted_file, ">", $unsorted_primers;
    print $unsorted_file join("\n", @{$bed_format_primers});
    close $unsorted_file;

    # Create a command for sortBed
    my $sort_bed_cmd = join(" ",
        $self->sort_bed_path,
        '-i',
        $unsorted_primers,
        '>',
        $sorted_primers
    );

    # Execute the command using IPC::Run3
    run3 $sort_bed_cmd, undef, undef, undef;

    # Make sure the sorted primer coordinates have been written to file
    unless ( -s $sorted_primers ) {
        croak "\n\nUnable to create a file of sorted primer coordinates.\n\n";
    }

    return $sorted_primers;
}

=head2 annotate_primers

This subroutine takes the following arguments:

    1. The path to the genomic index file for the user-defined genome
    2. The path to the primer coordinates

Both of these files should be in BED-format and sorted by chromosome and start
position. This allows for the use of chromsweep algorithm, which uses far less
resources. This subroutine returns a Hash Ref of information indexed by primer
pair name.

=cut

sub annotate_primers  {
    my $self = shift;
    my $genomic_index_file = shift;
    my $primer_index_file = shift;

    # Pre-declare a Hash Ref to hold the genes close to each primer pair
    my $primers_to_genes = {};

    # Create a File::Temp object to hold the results of the intersectBed call
    my $intersect_bed_results = File::Temp->new();

    # Define a call for intersectBed
    my $intersect_bed_cmd = join(" ",
        $self->intersect_bed_path,
        '-wao',
        '-sorted',
        '-a',
        $primer_index_file,
        '-b',
        $genomic_index_file,
        '>',
        $intersect_bed_results
    );

    # Execute the command using IPC::Run3
    run3 $intersect_bed_cmd, undef, undef, undef;

    # Open the results file, iterate through and parse the results into the
    # primers_to_genes Hash Ref
    open my $primer_results, "<", $intersect_bed_results;
    while(<$primer_results>) {
        my $line = $_;
        chomp($line);

        # Split the line by tabs
        my @line_items = split(/\t/, $line);

        # If the primer pair is near a gene, calculate the relative genomic
        # coordinates to the nearest gene, otherwise indicate that the primer
        # pair is not close to a RefSeq gene.
        if ( $line_items[-1] ) {

            # Calculate how far the gene was extended
            my $extension_length = int(
                (
                    (
                        (
                            $line_items[6] - $line_items[5]
                        ) - int(
                            (
                                ( $line_items[6] - $line_items[5] + 1) * 2 / 3 
                            ) + 0.5
                        )
                    ) / 2
                ) + 0.5
            );

            # Calculate the actual gene ends with respect to the positive strand
            my $five_prime = $line_items[5] + $extension_length;
            my $three_prime = $line_items[6] - $extension_length;

            # Calculate the distances from the 5' and 3' ends of the gene with
            # respect to the positive strand
            my $five_prime_distance = min(
                abs($five_prime - $line_items[1]),
                abs($five_prime - $line_items[2]),
            );
            my $three_prime_distance = min(
                abs($three_prime - $line_items[1]),
                abs($three_prime - $line_items[2]),
            );

            # Determine if the primer pair is within the gene body.
            if ( $line_items[1] >= $line_items[5] &&
                $line_items[2] <= $line_items[6] ) {

                # The primer pair is within the gene body
                #
                # Based on which strand the gene is on report how far the primer
                # pair is from the TSS and TTS
                if ( $line_items[8] eq '+' ) {
                    push(@{$primers_to_genes->{$line_items[3]}},
                        'Within the gene body of ' . $line_items[7] . '. ' .
                        $five_prime_distance . 'bp from the TSS and ' .
                        $three_prime_distance . 'bp from the TTS.'
                    );
                } else {
                    push(@{$primers_to_genes->{$line_items[3]}},
                        'Within the gene body of ' . $line_items[7] . '. ' .
                        $three_prime_distance . 'bp from the TSS and ' .
                        $five_prime_distance . 'bp from the TTS.'
                    );
                }
            } else {

                # Based on which strand the gene is on, report how far the
                # primer pair is from the TSS or TTS
                if ( $line_items[8] eq '+' ) {

                    # Test whether the primer pair is closer to the TSS or TTS
                    if ( $five_prime_distance < $three_prime_distance ) {
                        push(@{$primers_to_genes->{$line_items[3]}},
                            '5\' of the TSS of ' . $line_items[7] . '. by ' .
                            $five_prime_distance . 'bp.'
                        );
                    } else {
                        push(@{$primers_to_genes->{$line_items[3]}},
                            '3\' of the TTS of ' . $line_items[7] . '. by ' .
                            $three_prime_distance . 'bp.'
                        );
                    }
                } else {

                    # Test whether the primer pair is close to the TSS or TTS
                    if ( $three_prime_distance < $five_prime_distance ) {
                        push(@{$primers_to_genes->{$line_items[3]}},
                            '5\' of the TSS of ' . $line_items[7] . '. by ' .
                            $three_prime_distance . 'bp.'
                        );
                    } else {
                        push(@{$primers_to_genes->{$line_items[3]}},
                            '3\' of the TTS of ' . $line_items[7] . '. by ' .
                            $five_prime_distance . 'bp.'
                        );
                    }
                }
            }
        } else {
            push(@{$primers_to_genes->{$line_items[3]}},
                'Not close to any genes in RefSeq'
            );
        }
    }

    return $primers_to_genes;
}

1;
