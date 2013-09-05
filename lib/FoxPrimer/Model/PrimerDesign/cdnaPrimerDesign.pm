package FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign;
use Moose;
use Carp;
use File::Which;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment;
use FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::MapPrimers;
use Data::Dumper;

with 'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3';
with 'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever';

use namespace::autoclean;

=head1 NAME

FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign - Catalyst Model

=head1 DESCRIPTION

This is the sub-controller module that controls the execution of functions to
design and annotate primers for cDNA/mRNA.

=head1 AUTHOR

Jason R Dobson L<foxprimer@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

=head2 number_per_type

This Moose object is the pre-validated number of primers per type of primer pair
to make.

=cut

has number_per_type =>  (
    is      =>  'ro',
    isa     =>  'Int',
);

=head2 product_size_string

This Moose object is the pre-validated string for the upper and lower
limits of acceptable PCR product sizes.

=cut

has product_size_string =>  (
    is      =>  'ro',
    isa     =>  'Str',
);

=head2 intron_size

This Moose object is the pre-validated integer value for the minimum size of an
intron between two primer pairs for a pair to be considered an "intron primer
pair".

=cut

has intron_size =>  (
    is      =>  'ro',
    isa     =>  'Int',
);

=head2 species

This Moose object contains the string of the species entered in the dropdown box
by the user on the web form.

=cut

has species =>  (
    is      =>  'ro',
    isa     =>  'Str',
);

=head2 mispriming_file

This Moose object is dynamically created based on which species the user picks
on the web form. This object contains the location of the appropriate mispriming
file to be used by Primer3 in scalar string format.

=cut

has mispriming_file    =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_mispriming_file',
    writer      =>  '_set_mispriming_file',
);

before  'mispriming_file'   =>  sub {
    my $self = shift;
    unless ( $self->has_mispriming_file ) {
        $self->_set_mispriming_file($self->_link_mispriming_file);
    }
};

=head2 _link_mispriming_file

This private subroutine is dynamically run to determine which mispriming file
will be used for primer design.

=cut

sub _link_mispriming_file   {
    my $self = shift;

    if ($self->species eq 'Human') {
        return "$FindBin::Bin/../root/static/files/human_and_simple";
    } else {
        return "$FindBin::Bin/../root/static/files/rodent_and_simple";
    }
}

=head2 primers_to_make

This Moose object is an Array Ref of Hash Refs containing the pertinant
information about the sequences to fectch from NCBI for the mRNA's found in the
Gene2Accession database.

Each field in the Array Ref has the following:
{
    mrna        =>  'RefSeq mRNA Accession',
    mrna_gi     =>  'NCBI GI Accession for cDNA sequence',
    dna_gi      =>  'NCBI GI Accession for genomic DNA sequence',
    dna_start   =>  'DNA position of the 5'-end of the mRNA',
    dna_stop    =>  'DNA position of the 3'-end of the mRNA',
    orientation =>  'Which strand of DNA the mRNA is found on'
}

=cut

has primers_to_make =>  (
    is          =>  'ro',
    isa         =>  'ArrayRef[HashRef]',
);

=head2 create_primers

This subroutine is the main subroutine for the Model. It creates the
objects of each subtype and relays the relevant information back and forth
between them. This subroutine returns the primers in an Array Ref of Hash
Refs as well as any error messages returned by Primer3.

=cut

sub create_primers {
    my $self = shift;

    # Pre-declare an Array Ref to hold the Hash Refs of primer information.
    my $designed_primers = [];

    # Pre-declare an Array Ref to hold any error messages returned by
    # Primer3.
    my $error_messages = [];

    # Iterate through the primers to design, fetch the sequence objects, align
    # the cDNA to the gDNA, design primers, and map the resultant primers to
    # exons as defined by sim4
    foreach my $mrna_info ( @{$self->primers_to_make} ) {

        # Run the get_objects subroutine consumed from
        # FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever to
        # get a cDNA sequence object, a gDNA sequence object, an mRNA
        # description and a cDNA sequence as a string
        my ($cdna_object, $genomic_dna_object, $description,
            $cdna_sequence_string) = $self->get_objects(
            $mrna_info->{mrna_gi},
            $mrna_info->{dna_gi},
            $mrna_info->{dna_start},
            $mrna_info->{dna_stop},
            $mrna_info->{orientation},
        );

        # Create a
        # FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankToFasta
        # object, and run the 'write_to_fasta' subroutine to write the
        # sequence objects to file.
#        my $genbank_to_fasta =
#        FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankToFasta->new(
#            mrna                =>  $sequence_object_set->{mrna},
#            cdna_object         =>  $sequence_object_set->{mrna_object},
#            genomic_dna_object  =>  $sequence_object_set->{genomic_dna_object},
#        );
#        my ($cdna_fh, $genomic_dna_fh) = $genbank_to_fasta->write_to_fasta;

        # Create a
        # FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment
        # object and run the 'sim4_alignment' subroutine to return a Hash
        # Ref of exon coordinates and intron lengths.
        my $sim4 =
        FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment->new(
#            cdna_fh         =>  $cdna_fh,
#            genomic_dna_fh  =>  $genomic_dna_fh
#        );
            cdna_fh         =>  $cdna_object,
            genomic_dna_fh  =>  $genomic_dna_object,
        );
        my $coordinates = $sim4->sim4_alignment;

        # Get rid of the sequence objects.
        close $cdna_object;
        close $genomic_dna_object;
        unlink($cdna_object);
        unlink($genomic_dna_object);
#        # Create a FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3
#        # object and run the 'create_primers' subroutine to return created
#        # primers, any error messages, and the number of primers designed by
#        # Primer3.
#        my $primer3 =
#        FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3->new(
#            product_size    =>  $self->product_size_string,
#            mispriming_file =>  $self->mispriming_file,
#            primer3_path    =>  $self->primer3_executable,
#            cdna_fh         =>  $cdna_fh
#        );

        # Run the 'make_primer3_primers' subroutine that is consumed from
        # FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3
        my ($created_primers, $primer3_errors, $number_of_primers_created)
        = $self->make_primer3_primers(
            $self->product_size_string,
            $self->mispriming_file,
            $cdna_sequence_string,
        );

        push(@{$error_messages}, $primer3_errors) if $primer3_errors;

        # Remove the FASTA files now that the alignment has completed and
        # primers have been designed.
#        unlink($cdna_fh);
#        unlink($genomic_dna_fh);

        # Remove the temporary file created by Primer3
#        unlink("$FindBin::Bin/../tmp/primer3/temp.out");

        # Now create an instance of
        # FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::MapPrimers to
        # run the 'map' subroutine, which will determine the top N of each
        # primer type based on the number (N) specified by the user and
        # ranked by the primer pair penalty defined by Primer3.
        my $map_primers =
        FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::MapPrimers->new(
            number_per_type         =>  $self->number_per_type,
            number_of_primers       =>  $number_of_primers_created,
            intron_size             =>  $self->intron_size,
            number_of_alignments    =>  
                $coordinates->{'Number of Alignments'},
            designed_primers        =>  $created_primers,
            coordinates             =>  $coordinates,
            mrna                    =>  $mrna_info->{mrna},
            description             =>  $description,
        );

        # Add the mapped primers (as an insert statement) to the
        # designed_primers Array Ref
        push(@$designed_primers, @{$map_primers->map});
    }

    return ($designed_primers, $error_messages);
}

__PACKAGE__->meta->make_immutable;

1;
