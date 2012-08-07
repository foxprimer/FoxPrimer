use utf8;
package FoxPrimer::Schema::Result::Gene2accession;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FoxPrimer::Schema::Result::Gene2accession

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<gene2accession>

=cut

__PACKAGE__->table("gene2accession");

=head1 ACCESSORS

=head2 mrna

  data_type: 'text'
  is_nullable: 1

=head2 mrna_root

  data_type: 'text'
  is_nullable: 1

=head2 mrna_gi

  data_type: 'text'
  is_nullable: 1

=head2 dna_gi

  data_type: 'text'
  is_nullable: 1

=head2 dna_start

  data_type: 'text'
  is_nullable: 1

=head2 dna_stop

  data_type: 'text'
  is_nullable: 1

=head2 orientation

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "mrna",
  { data_type => "text", is_nullable => 1 },
  "mrna_root",
  { data_type => "text", is_nullable => 1 },
  "mrna_gi",
  { data_type => "text", is_nullable => 1 },
  "dna_gi",
  { data_type => "text", is_nullable => 1 },
  "dna_start",
  { data_type => "text", is_nullable => 1 },
  "dna_stop",
  { data_type => "text", is_nullable => 1 },
  "orientation",
  { data_type => "text", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-06-12 18:17:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4MQmVO5s7E/0APeTgaJeNQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
