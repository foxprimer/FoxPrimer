package FoxPrimer::Model::Primer_Database;
use Moose::Role;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Schema;
use FoxPrimer::Model::UCSC;
use Data::Dumper;

=head1 NAME

FoxPrimer::Model::Primer_Database - Catalyst Model

=head1 DESCRIPTION

This module provides the methods for interactions with the FoxPrimer databases.

=head1 AUTHOR

Jason R Dobson, L<foxprimer@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

=head2 cdna_primer_schema

This Moose attribute holds the FoxPrimer::Schema object used to connect to the
cDNA primers database.

=cut

has cdna_primer_schema  =>  (
    is          =>  'ro',
    isa         =>  'FoxPrimer::Schema',
    writer      =>  '_set_cdna_primer_schema',
    predicate   =>  'has_cdna_primer_schema',
);

before  'cdna_primer_schema'    =>  sub {
    my $self = shift;
    unless ( $self->has_cdna_primer_schema ) {
        $self->_set_cdna_primer_schema( 
            $self->_get_cdna_primer_schema
        );
    }
};

=head2 _get_cdna_primer_schema

This private subroutine is dynamically run to get the FoxPrimer::Schema object
to interact with the cDNA primers database.

=cut

sub _get_cdna_primer_schema {
    my $self = shift;
    return FoxPrimer::Schema->connect(
        "dbi:SQLite:$FindBin::Bin/../db/primers.db"
    );
}

=head2 gene2accession_schema

This Moose attribute holds a FoxPrimer::Schema object that allows for
interaction with the gene2accession database.

=cut

has gene2accession_schema   =>  (
    is          =>  'ro',
    isa         =>  'FoxPrimer::Schema',
    writer      =>  '_set_gene2accession_schema',
    predicate   =>  'has_gene2accession_schema',
);

before  'gene2accession_schema' =>  sub {
    my $self = shift;
    unless ($self->has_gene2accession_schema) {
        $self->_set_gene2accession_schema(
            $self->_get_gene2accession_schema
        );
    }
};

=head2 _get_gene2accession_schema

This private subroutine is run dynamically to return a FoxPrimer::Schema object
for interaction with the gene2accession database.

=cut

sub _get_gene2accession_schema  {
    my $self = shift;
    return FoxPrimer::Schema->connect(
        "dbi:SQLite:$FindBin::Bin/../db/gene2accession.db"
    );
}

=head2 chip_genomes_schema

This Moose attribute contains the schema for connecting to the ChIP Genomes
FoxPrimer database.

=cut

has chip_genomes_schema =>  (
    is          =>  'ro',
    isa         =>  'FoxPrimer::Schema',
    predicate   =>  'has_chip_genomes_schema',
    writer      =>  '_set_chip_genomes_schema',
);

before  'chip_genomes_schema'   =>  sub {
    my $self = shift;
    unless ($self->has_chip_genomes_schema) {
        $self->_set_chip_genomes_schema($self->_get_chip_genomes_schema);
    }
};

=head2 _get_chip_genomes_schema

This private subroutine is dynamically run to return a FoxPrimer::Schema object
that connects to the ChIP Genomes Schema.

=cut

sub _get_chip_genomes_schema    {
    my $self = shift;
    my $dsn = "dbi:SQLite:$FindBin::Bin/../db/chip_genomes.db";
    my $schema = FoxPrimer::Schema->connect($dsn, '', '', '');
    return $schema;
}

=head2 define_ucsc_schema

This subroutine is passed a genome string and returns a DBIx::Class::Schema
object with a connection to the UCSC MySQL server.

=cut

sub define_ucsc_schema {
    my $self = shift;
    my $genome = shift;
    
    # Connect to the UCSC MySQL Browser
    my $schema =
    FoxPrimer::Model::UCSC->connect('dbi:mysql:host=genome-mysql.cse.ucsc.edu;database='
        . $genome, "genome");
    return $schema;
}

=head2 prepare_insert_lines

This subroutine prepares lines to be inserted by the controller into
the primer database.

=cut

sub prepare_insert_lines {
    my ($self, $mapped_primers, $description, $rna_accession) = @_;
    foreach my $primer_pair ( keys %$mapped_primers ) {
        my $primer_type_string;
        if ( ($mapped_primers->{$primer_pair}{'Primer Pair Type'} eq 'Smaller Exon Primer Pair') ||
            ($mapped_primers->{$primer_pair}{'Primer Pair Type'} eq 'Exon Primer Pair') ) {
            $primer_type_string = 'Flanking Intron(s): ' . $mapped_primers->{$primer_pair}{'Sum of Introns Size'}
        } else {
            $primer_type_string = $mapped_primers->{$primer_pair}{'Primer Pair Type'};
        }
        my $schema = FoxPrimer::Schema->connect('dbi:SQLite:db/primers.db');
        my $result_class = $schema->resultset('Primer');
        $result_class->update_or_create(
            'primer_type'               =>  $primer_type_string,
            'description'               =>  $description,
            'mrna'                      =>  $rna_accession,
            'primer_pair_number'        =>  $primer_pair,
            'left_primer_sequence'      =>  $mapped_primers->{$primer_pair}{'Left Primer Sequence'},
            'right_primer_sequence'     =>  $mapped_primers->{$primer_pair}{'Right Primer Sequence'},
            'left_primer_tm'            =>  $mapped_primers->{$primer_pair}{'Left Primer Tm'},
            'right_primer_tm'           =>  $mapped_primers->{$primer_pair}{'Right Primer Tm'},
            'left_primer_coordinates'   =>  $mapped_primers->{$primer_pair}{'Left Primer Coordinates'},
            'right_primer_coordinates'  =>  $mapped_primers->{$primer_pair}{'Right Primer Coordinates'},
            'product_size'              =>  $mapped_primers->{$primer_pair}{'Product Size'},
            'product_penalty'           =>  $mapped_primers->{$primer_pair}{'Product Penalty'},
            'left_primer_position'      =>  $mapped_primers->{$primer_pair}{'Left Primer Position'},
            'right_primer_position'     =>  $mapped_primers->{$primer_pair}{'Right Primer Position'},
        );
    }
}

1;
