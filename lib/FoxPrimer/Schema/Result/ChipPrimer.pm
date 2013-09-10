use utf8;
package FoxPrimer::Schema::Result::ChipPrimer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FoxPrimer::Schema::Result::ChipPrimer

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

=head1 TABLE: C<chip_primers>

=cut

__PACKAGE__->table("chip_primers");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 left_primer_sequence

  data_type: 'text'
  is_nullable: 1

=head2 right_primer_sequence

  data_type: 'text'
  is_nullable: 1

=head2 left_primer_tm

  data_type: 'number'
  is_nullable: 1

=head2 right_primer_tm

  data_type: 'number'
  is_nullable: 1

=head2 genome

  data_type: 'text'
  is_nullable: 1

=head2 chromosome

  data_type: 'text'
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

=head2 product_size

  data_type: 'integer'
  is_nullable: 1

=head2 primer_pair_penalty

  data_type: 'number'
  is_nullable: 1

=head2 relative_locations

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "left_primer_sequence",
  { data_type => "text", is_nullable => 1 },
  "right_primer_sequence",
  { data_type => "text", is_nullable => 1 },
  "left_primer_tm",
  { data_type => "number", is_nullable => 1 },
  "right_primer_tm",
  { data_type => "number", is_nullable => 1 },
  "genome",
  { data_type => "text", is_nullable => 1 },
  "chromosome",
  { data_type => "text", is_nullable => 1 },
  "left_primer_five_prime",
  { data_type => "integer", is_nullable => 1 },
  "left_primer_three_prime",
  { data_type => "integer", is_nullable => 1 },
  "right_primer_five_prime",
  { data_type => "integer", is_nullable => 1 },
  "right_primer_three_prime",
  { data_type => "integer", is_nullable => 1 },
  "product_size",
  { data_type => "integer", is_nullable => 1 },
  "primer_pair_penalty",
  { data_type => "number", is_nullable => 1 },
  "relative_locations",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<left_primer_sequence_right_primer_sequence_genome_unique>

=over 4

=item * L</left_primer_sequence>

=item * L</right_primer_sequence>

=item * L</genome>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "left_primer_sequence_right_primer_sequence_genome_unique",
  ["left_primer_sequence", "right_primer_sequence", "genome"],
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-09-09 14:15:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wwCPd/n1+YVQM9hVG+wbVg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
