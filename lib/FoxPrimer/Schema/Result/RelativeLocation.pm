use utf8;
package FoxPrimer::Schema::Result::RelativeLocation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FoxPrimer::Schema::Result::RelativeLocation

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

=head1 TABLE: C<relative_locations>

=cut

__PACKAGE__->table("relative_locations");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 location

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "location",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<location_unique>

=over 4

=item * L</location>

=back

=cut

__PACKAGE__->add_unique_constraint("location_unique", ["location"]);

=head1 RELATIONS

=head2 chip_primer_pairs_relative_locations

Type: has_many

Related object: L<FoxPrimer::Schema::Result::ChipPrimerPairsRelativeLocation>

=cut

__PACKAGE__->has_many(
  "chip_primer_pairs_relative_locations",
  "FoxPrimer::Schema::Result::ChipPrimerPairsRelativeLocation",
  { "foreign.location_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pairs

Type: many_to_many

Composing rels: L</chip_primer_pairs_relative_locations> -> pair

=cut

__PACKAGE__->many_to_many("pairs", "chip_primer_pairs_relative_locations", "pair");


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-08-18 12:46:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ndhBhFCv70GfZf1FMC/fiA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
