use utf8;
package FoxPrimer::Schema::Result::ChipPrimerPairsRelativeLocation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FoxPrimer::Schema::Result::ChipPrimerPairsRelativeLocation

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

=head1 TABLE: C<chip_primer_pairs_relative_locations>

=cut

__PACKAGE__->table("chip_primer_pairs_relative_locations");

=head1 ACCESSORS

=head2 pair_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 location_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "pair_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "location_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pair_id>

=item * L</location_id>

=back

=cut

__PACKAGE__->set_primary_key("pair_id", "location_id");

=head1 RELATIONS

=head2 location

Type: belongs_to

Related object: L<FoxPrimer::Schema::Result::RelativeLocation>

=cut

__PACKAGE__->belongs_to(
  "location",
  "FoxPrimer::Schema::Result::RelativeLocation",
  { id => "location_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 pair

Type: belongs_to

Related object: L<FoxPrimer::Schema::Result::ChipPrimerPairsGeneral>

=cut

__PACKAGE__->belongs_to(
  "pair",
  "FoxPrimer::Schema::Result::ChipPrimerPairsGeneral",
  { id => "pair_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-03-03 17:41:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rgqKeQNNL4fkAla67NCkpQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
