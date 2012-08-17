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
  is_nullable: 1

=head2 location_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pair_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "location_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 RELATIONS

=head2 location

Type: belongs_to

Related object: L<FoxPrimer::Schema::Result::RelativeLocation>

=cut

__PACKAGE__->belongs_to(
  "location",
  "FoxPrimer::Schema::Result::RelativeLocation",
  { id => "location_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 pair

Type: belongs_to

Related object: L<FoxPrimer::Schema::Result::ChipPrimerPairsGeneral>

=cut

__PACKAGE__->belongs_to(
  "pair",
  "FoxPrimer::Schema::Result::ChipPrimerPairsGeneral",
  { id => "pair_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-08-17 13:02:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rgWsz/sngUbdxFjokN86Xw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
