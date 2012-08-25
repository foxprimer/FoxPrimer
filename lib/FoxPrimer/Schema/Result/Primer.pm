use utf8;
package FoxPrimer::Schema::Result::Primer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FoxPrimer::Schema::Result::Primer

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

=head1 TABLE: C<primers>

=cut

__PACKAGE__->table("primers");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 accession

  data_type: 'text'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 primer_pair_type

  data_type: 'text'
  is_nullable: 1

=head2 primer_pair_penalty

  data_type: 'numeric'
  is_nullable: 1

=head2 left_primer_position

  data_type: 'text'
  is_nullable: 1

=head2 right_primer_position

  data_type: 'text'
  is_nullable: 1

=head2 product_size

  data_type: 'integer'
  is_nullable: 1

=head2 left_primer_sequence

  data_type: 'text'
  is_nullable: 1

=head2 right_primer_sequence

  data_type: 'text'
  is_nullable: 1

=head2 left_primer_length

  data_type: 'integer'
  is_nullable: 1

=head2 right_primer_length

  data_type: 'integer'
  is_nullable: 1

=head2 left_primer_tm

  data_type: 'numeric'
  is_nullable: 1

=head2 right_primer_tm

  data_type: 'numeric'
  is_nullable: 1

=head2 left_primer_five_prime

  data_type: 'integer'
  is_nullable: 1

=head2 left_primer_three_prime

  data_type: 'integer'
  is_nullable: 1

=head2 right_primer_five_prime

  data_type: 'integer'
  is_nullable: 1

=head2 right_primer_three_prime

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "accession",
  { data_type => "text", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "primer_pair_type",
  { data_type => "text", is_nullable => 1 },
  "primer_pair_penalty",
  { data_type => "numeric", is_nullable => 1 },
  "left_primer_position",
  { data_type => "text", is_nullable => 1 },
  "right_primer_position",
  { data_type => "text", is_nullable => 1 },
  "product_size",
  { data_type => "integer", is_nullable => 1 },
  "left_primer_sequence",
  { data_type => "text", is_nullable => 1 },
  "right_primer_sequence",
  { data_type => "text", is_nullable => 1 },
  "left_primer_length",
  { data_type => "integer", is_nullable => 1 },
  "right_primer_length",
  { data_type => "integer", is_nullable => 1 },
  "left_primer_tm",
  { data_type => "numeric", is_nullable => 1 },
  "right_primer_tm",
  { data_type => "numeric", is_nullable => 1 },
  "left_primer_five_prime",
  { data_type => "integer", is_nullable => 1 },
  "left_primer_three_prime",
  { data_type => "integer", is_nullable => 1 },
  "right_primer_five_prime",
  { data_type => "integer", is_nullable => 1 },
  "right_primer_three_prime",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<left_primer_sequence_right_primer_sequence_accession_unique>

=over 4

=item * L</left_primer_sequence>

=item * L</right_primer_sequence>

=item * L</accession>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "left_primer_sequence_right_primer_sequence_accession_unique",
  ["left_primer_sequence", "right_primer_sequence", "accession"],
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-08-24 18:14:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3q1tHV/E/1Yj5e9P5XGHBQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
