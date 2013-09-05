package FoxPrimer::Model::PrimerDesign;
use Moose;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Schema;
use FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign;
use FoxPrimer::Model::PrimerDesign::chipPrimerDesign;
use namespace::autoclean;

with 'FoxPrimer::Model::Primer_Database';

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

Jason R Dobson L<foxprimer@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 product_size_string

This Moose object is used to store the user-defined product size string. By
default it is set to 70-150 (bp) as it is in the Template Toolkit webpage,

=cut

has product_size_string =>  (
    is          =>  'ro',
    isa         =>  'Str',
);

=head2 max_number_per_type

This Moose object is used to store the administrator-defined max value for
the number of cDNA primers that will be made for each type of primer.

=cut

has max_number_per_type => (
    is          =>  'ro',
    isa         =>  'Int',
    required    =>  1,
    # Change the default value here based on your server limitations.
    default     =>  10,
    lazy        =>  1,
);

=head2 number_per_type

This Moose object is defined by the user in the webpage as the number of
primer pairs they wish to make per type. This value will be contrained by
the administrator-defined maximum value.

=cut

has number_per_type =>  (
    is          =>  'ro',
    isa         =>  'Str',
);

=head2 intron_size

This Moose object is defined by the user in the webpage as the minimum
intron size to be used when defining the type of primer pair types.

=cut

has intron_size =>  (
    is          =>  'ro',
    isa         =>  'Str'
);

=head2 accessions_string

This Moose object holds the string of RefSeq mRNA accessions that the user
would like to create cDNA primers for.

=cut

has accessions_string   =>  (
    is          =>  'ro',
    isa         =>  'Str',
);

=head2 species

This Moose object is defined by the use in the dropdown box, and will be
used to determine which mispriming file is appropriate for primer3.

=cut

has species =>  (
    is          =>  'ro',
    isa         =>  'Str',
);

#=head2 gene2accession_schema
#
#This Moose object is created by a lazy loader, which will create a
#DBIx::Class::ResultSet object for the Gene2Accession database. This object
#is private and can not be modified upon creation of a
#FoxPrimer::Model::PrimerDesign object.
#
#=cut
#
#has _gene2accession_schema  =>  (
#    is          =>  'ro',
#    isa         =>  'FoxPrimer::Schema',
#    default     =>  sub {
#        my $self = shift;
#        my $dsn = "dbi:SQLite:$FindBin::Bin/../db/gene2accession.db";
#        my $schema = FoxPrimer::Schema->connect($dsn, '', '', '');
#        return $schema;
#    },
#    required    =>  1,
#    reader      =>  'gene2accession_schema',
#);

#=head2 _chip_genomes_schema
#
#This Moose object contains the Schema for connecting to the ChIP Genomes
#FoxPrimer database
#
#=cut
#
#has _chip_genomes_schema    =>  (
#    is          =>  'ro',
#    isa         =>  'FoxPrimer::Schema',
#    default     =>  sub {
#        my $self = shift;
#        my $dsn = "dbi:SQLite:$FindBin::Bin/../db/chip_genomes.db";
#        my $schema = FoxPrimer::Schema->connect($dsn, '', '', '');
#        return $schema;
#    },
#    required    =>  1,
#    reader      =>  'chip_genomes_schema',
#);

=head2 genome

This Moose object contains the scalar string for the user-defined genome
for which they would like to design ChIP primers.

=cut

has genome  =>  (
    is          =>  'ro',
    isa         =>  'Str',
);

=head2 motif

This Moose object contains the scalar string for the user-defined motif for
which the user would like their primer pairs to be centered around.

=cut

has motif   =>  (
    is          =>  'ro',
    isa         =>  'Str',
);

=head2 chip_primers_coordinates

This Moose object contains the path to the user-uploaded file containing
the information for ChIP primer design.

=cut

has chip_primers_coordinates    =>  (
    is          =>  'ro',
    isa         =>  'Str'
);

=head2 _max_bed_lines

This private Moose object is to be controlled by the administrator based
on their server's capabilities. This controls how many lines of the BED
file uploaded by the user that will be read in for ChIP primer design. By
default this value is set to 10.

=cut

has _max_bed_lines  =>  (
    is          =>  'ro',
    isa         =>  'Int',
    default     =>  10,
    required    =>  1,
    lazy        =>  1,
    reader      =>  'max_bed_lines',
);

=head2 validate_mrna_form

This subroutine is called by the FoxPrimer Controller module to ensure that the
fields entered by the user for the creation of cDNA primers is valid.  This
subroutine will return any error messages to the Controller in the form of an
Array Ref, and it will return an Array Ref of Hash Refs of the information
needed to design primers once the other fields have been validated. This
subroutine will also return an Array Ref of messages about RefSeq mRNA
accessions entered by the user, which were not found or not valid.

=cut

sub validate_mrna_form {
    my $self = shift;

    # Pre-declare an Array Ref to hold any error messages to return to the user.
    my $form_errors = [];

    # Determine if the field entered for the product size is valid by running
    # the FoxPrimer::Model::PrimerDesign::validate_product_size subroutine.
    my $product_size_errors = $self->validate_product_size;

    # If there are any errors, add them to the form_errors Array Ref
    if ( $product_size_errors && (scalar (@{$product_size_errors}) >= 1 )) {
        push(@{$form_errors}, @{$product_size_errors});
    }

    # Determine if the number to make field is valid by running the
    # FoxPrimer::Model::PrimerDesign::validate_number_per_type subroutine.
    my $number_per_type_errors = $self->validate_number_per_type;

    # If there are any errors, add them to the form_errors Array Ref
    if ( $number_per_type_errors && ( scalar(@{$number_per_type_errors}) >= 1))
    {
        push(@{$form_errors}, @{$number_per_type_errors});
    }

    # Determine if the minimum intron size field is valid by running the
    # FoxPrimer::Model::PrimerDesign::validate_intron_size subroutine.
    my $intron_size_errors = $self->validate_intron_size;

    # If there are any errors, add them to the form_errors Array Ref
    if ( $intron_size_errors && ( scalar(@{$intron_size_errors}) >= 1)) {
        push(@{$form_errors}, @{$intron_size_errors});
    }

    # If there are any errors in the fields checked this far, do not check
    # to see if the mRNAs entered were valid. Return the error messages to
    # the user and end.
    if ( $form_errors && (scalar(@{$form_errors}) >= 1) ) {
        return($form_errors, [], []);
    } else {
        # Run the valid_refseq_accessions subroutine, and return the results to
        # the Controller.
        my ($accession_errors, $accessions_to_make_primers) =
        $self->valid_refseq_accessions;
        return (
            $form_errors, 
            $accession_errors,
            $accessions_to_make_primers
        );
    }
}

=head2 validate_chip_form

This is the main subroutine called by the FoxPrimer Catalyst controller.
This subroutine makes calls to validate the product size, genome, motif (if
entered) and the form of coordinates uploaded by the user. If there are any
errors in any of these parameters, a verbose message is returned to the
FoxPrimer Controller and execution will end.

=cut

sub validate_chip_form {
    my $self = shift;

    # Pre-declare an Array Ref to hold an error messages to be returned to
    # the user.
    my $form_errors = [];

    # Determine if the field entered for the product size is valid by
    # running the FoxPrimer::Model::PrimerDesign::validate_product_size
    # subroutine.
    my $product_size_errors = $self->validate_product_size;

    # If there are any errors, add them to the form_errors Array Ref
    if (@$product_size_errors) {
        push(@$form_errors, @$product_size_errors);
    }

    # Determine whether the genome entered by the user has been installed
    # in the FoxPrimer database.
    my $genome_error = $self->validate_genome;

    # If there are any errors, add them to the form_errors Array Ref
    if ( $genome_error ) {
        push(@$form_errors, $genome_error);
    }

    # Determine whether the motif entered by the user has been installed in
    # the FoxPrimer database.
    unless ( $self->motif eq 'No Motif' || ! $self->motif ) {
        my $motif_errors = $self->validate_motif;

        # If there are any motif errors, add them to the form_errors Array
        # Ref.
        if (@$motif_errors) {
            push(@$form_errors, @$motif_errors);
        }
    }

    return $form_errors;
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
                -or =>  
                [
                    'mrna'      =>  $accession_to_test,
                    'mrna_root' =>  $accession_to_test,
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
                        mrna        =>  $found_rna->mrna,
                        mrna_gi     =>  $found_rna->mrna_gi,
                        dna_gi      =>  $found_rna->dna_gi,
                        dna_start   =>  $found_rna->dna_start,
                        dna_stop    =>  $found_rna->dna_stop,
                        orientation =>  $found_rna->orientation,
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

=head2 validate_genome

This subroutine is used to ensure that the user-defined genome for
designing ChIP primers has been installed in the FoxPrimer database. If the
genome has not been installed, an error message is returned.

=cut

sub validate_genome {
    my $self = shift;

    # Search the Genome table in the ChIP genome database for the
    # user-defined genome.
    my $search_result =
    $self->chip_genomes_schema->resultset('Genome')->find(
        {
            genome  =>  $self->genome
        }
    );

    # If the genome is found, return an empty string, otherwise return an
    # error indicating that the user-defined genome was not installed. This
    # should typically not happen because the Template Toolkit form uses a
    # drop-down menu (defined by the ChIP genomes database) to control
    # which genomes can be chosen by the user.
    if ( $search_result && $search_result->genome eq $self->genome ) {
        return '';
    } else {
        return 'The genome ' . $self->genome . ' is not installed.' .
        ' Please contact your administrator to insall the genome.';
    }
}

=head2 validate_motif

This subroutine is used to determine whether the user-defined motif is
valid and that the file corresponding to the motif can be found and read by
FoxPrimer.

=cut

sub validate_motif {
    my $self = shift;

    # Pre-declare an Array Ref to hold any error messages.
    my $motif_errors = [];
    
    # Pre-declare a Hash Ref to hold the motif names defined in the list of
    # motifs file.
    my $motifs = {};

    # Open the list of motifs file, iterate through the file and populate
    # the motifs Hash Ref.
    my $list_fh =
    "$FindBin::Bin/../root/static/meme_motifs/list_of_motifs_by_gene.txt";
    open my $list_file, "<", $list_fh or die "Could not read from $list_fh"
    . "$!";
    while (<$list_file>) {
        my $motif = $_;
        chomp($motif);
        $motifs->{$motif} = 1;
    }
    close $list_file;

    # Make sure the user-defined motif is found in the list file.
    unless ( $motifs->{$self->motif} ) {
        push(@$motif_errors, 
            'The motif ' . $self->motif . ' was not found in the list of '
            . 'valid motifs. Please consult your administrator to check ' . 
            'your installation of FoxPrimer'
        );
    }

    # Make sure the file associated with the user-defined motif is readable
    # by FoxPrimer
    my $motif_fh = "$FindBin::Bin/../root/static/meme_motifs/" .
    $self->motif . ".meme";
    unless ( -r $motif_fh ) {
        push(@$motif_errors,
            'The motif file ' . $motif_fh . ' for the motif ' .
            $self->motif . ' was not readbale by FoxPrimer. Please ' .
            'consult with your administrator to check the installation of '
            . 'FoxPrimer.'
        );
    }

    return $motif_errors;
}

=head2 valid_bed_file

This subroutine determines whether the file of coordinates for ChIP primer
design uploaded by the user is valid.

=cut

sub valid_bed_file {
    my $self = shift;

    # Pre-declare an Array Ref to hold any errors found in the user's file.
    my $bed_file_errors = [];

    # Pre-declare an Array Ref to hold the coordinates found in the user's
    # file.
    my $bed_file_coordinates = [];

    # Pre-define a line number so that useful errors can be returned to the
    # user.
    my $line_number = 0;

    # Create an instance of
    # FoxPrimer::Model::PrimerDesign::chipPrimerDesign and run the
    # chromosome_sizes subroutine to return a Hash Ref of chromosome names
    # as keys and chromosome lengths as key values.
    my $get_chromosome_sizes =
    FoxPrimer::Model::PrimerDesign::chipPrimerDesign->new(
        genome  =>  $self->genome
    );
    my $chromosome_sizes = $get_chromosome_sizes->chromosome_sizes;

    # Open the user-defined BED file, iterate through the lines, and test
    # the fields on each line to make sure they are valid.
    open my $bed_file, "<", $self->chip_primers_coordinates or die 
    "Could not read from " . $self->chip_primers_coordinates . "$!\n";
    while (<$bed_file>) {
        my $line = $_;
        chomp($line);

        # Increase the line number
        $line_number++;

        # Make sure that the max_bed_lines threshold has not been reached.
        if ( @$bed_file_coordinates < $self->max_bed_lines ) {

            # Split the BED file line by the tab character
            my @bed_line_items = split(/\t/, $line);

            # Make sure that the BED file line has enough information for
            # primer design.
            if ( @bed_line_items >= 3 ) {

                # Check each field to make sure that they are valid.
                #
                # The first field holds the chromosome string, make sure
                # the chromosome string is valid for the current genome.
                if ( $chromosome_sizes->{$bed_line_items[0]} ) {

                    # Check that the start and stop coordinates are valid
                    # integers for the given chromosome.
                    if ( $bed_line_items[1] && 
                        $bed_line_items[1] > 0 &&
                        $bed_line_items[1] <=
                        $chromosome_sizes->{$bed_line_items[0]} ) {
                        if ( $bed_line_items[2] && 
                            $bed_line_items[2] > 0 &&
                            $bed_line_items[2] <=
                            $chromosome_sizes->{$bed_line_items[0]} ) {

                            # Check to make sure the end coordinate is
                            # greater than the start coordinates.
                            if ( $bed_line_items[2] > $bed_line_items[1] )
                            {
                                
                                # Add the BED coordinates to the
                                # bed_file_coordinates Array Ref in the
                                # form of a Hash Ref.
                                push(@$bed_file_coordinates,
                                    {
                                        chromosome  =>  $bed_line_items[0],
                                        start       =>  $bed_line_items[1],
                                        end         =>  $bed_line_items[2],
                                    }
                                );
                            } else {
                                push(@$bed_file_errors,
                                    'The chromosome end position: ' .
                                    $bed_line_items[2] . ' is not ' .
                                    'greater than the chromosome start ' .
                                    'position: ' . $bed_line_items[1] .
                                    'on line: ' . $line_number . '.'
                                );
                            }
                        } else {
                            push(@$bed_file_errors, 
                                'The chromosome end position: ' .
                                $bed_line_items[2] . ' on line: ' .
                                $line_number . ' is not valid for the ' .
                                ' chromosome ' . $bed_line_items[0]
                            );
                        }
                    } else {
                        push(@$bed_file_errors, 
                            'The chromosome start position: ' .
                            $bed_line_items[1] . ' on line: ' .
                            $line_number . ' is not valid for the ' .
                            ' chromosome ' . $bed_line_items[0]
                        );
                    }
                } else {

                    # Don't check the rest of the fields, and return an
                    # error about this line.
                    push(@$bed_file_errors,
                        'The chromosome ' . $bed_line_items[0] . ' on line'
                        . $line_number . ' is not valid for the defined ' . 
                        'genome: ' . $self->genome . '.'
                    );
                }
            } else {

                # Return an error message for this line indicating that it
                # did not have enough information.
                push(@$bed_file_errors,
                    'Line ' . $line_number . ' does not have enough tab-' .
                    'separated fields. You must have four fields: ' .
                    'chromosome, start position, stop position, and peak '
                    . 'name.'
                );
            }
        } else {
            # Add an error message indicating that the current line
            # exceeded the maximum allowable BED coordinates for the
            # server.
            push(@$bed_file_errors,
                'Line number ' . $line_number . ' exceeds the ' .
                'administrator-defined maximum coordinates for ChIP' .
                ' primer design. Primers will not be made for these ' . 
                'coordinates.'
            );
        }
    }
    close $bed_file;

    return ($bed_file_errors, $bed_file_coordinates);
}

__PACKAGE__->meta->make_immutable;

1;
