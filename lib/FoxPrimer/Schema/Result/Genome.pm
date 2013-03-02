use utf8;
package FoxPrimer::Schema::Result::Genome;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FoxPrimer::Schema::Result::Genome

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

=head1 TABLE: C<genomes>

=cut

__PACKAGE__->table("genomes");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 genome

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "genome",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<genome_unique>

=over 4

=item * L</genome>

=back

=cut

__PACKAGE__->add_unique_constraint("genome_unique", ["genome"]);

=head1 RELATIONS

=head2 chromosomesizes

Type: has_many

Related object: L<FoxPrimer::Schema::Result::Chromosomesize>

=cut

__PACKAGE__->has_many(
  "chromosomesizes",
  "FoxPrimer::Schema::Result::Chromosomesize",
  { "foreign.genome" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 genebodies

Type: has_many

Related object: L<FoxPrimer::Schema::Result::Genebody>

=cut

__PACKAGE__->has_many(
  "genebodies",
  "FoxPrimer::Schema::Result::Genebody",
  { "foreign.genome" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 twobits

Type: has_many

Related object: L<FoxPrimer::Schema::Result::Twobit>

=cut

__PACKAGE__->has_many(
  "twobits",
  "FoxPrimer::Schema::Result::Twobit",
  { "foreign.genome" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-03-01 16:22:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rgmwbQA2Bs/K6tc5vS/i+g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
