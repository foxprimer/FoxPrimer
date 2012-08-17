use utf8;
package FoxPrimer::Schema::Result::ChipPrimerPairsGeneral;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FoxPrimer::Schema::Result::ChipPrimerPairsGeneral

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

=head1 TABLE: C<chip_primer_pairs_general>

=cut

__PACKAGE__->table("chip_primer_pairs_general");

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
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<left_primer_sequence_right_primer_sequence_unique>

=over 4

=item * L</left_primer_sequence>

=item * L</right_primer_sequence>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "left_primer_sequence_right_primer_sequence_unique",
  ["left_primer_sequence", "right_primer_sequence"],
);

=head1 RELATIONS

=head2 chip_primer_pairs_relative_locations

Type: has_many

Related object: L<FoxPrimer::Schema::Result::ChipPrimerPairsRelativeLocation>

=cut

__PACKAGE__->has_many(
  "chip_primer_pairs_relative_locations",
  "FoxPrimer::Schema::Result::ChipPrimerPairsRelativeLocation",
  { "foreign.pair_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-08-17 13:19:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UvugySrIttves0vqjock5g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
