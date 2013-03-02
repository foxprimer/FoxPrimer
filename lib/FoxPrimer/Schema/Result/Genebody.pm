use utf8;
package FoxPrimer::Schema::Result::Genebody;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FoxPrimer::Schema::Result::Genebody

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

=head1 TABLE: C<genebodies>

=cut

__PACKAGE__->table("genebodies");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 genome

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 accession

  data_type: 'text'
  is_nullable: 1

=head2 chromosome

  data_type: 'text'
  is_nullable: 1

=head2 txstart

  data_type: 'integer'
  is_nullable: 1

=head2 txend

  data_type: 'integer'
  is_nullable: 1

=head2 strand

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "genome",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "accession",
  { data_type => "text", is_nullable => 1 },
  "chromosome",
  { data_type => "text", is_nullable => 1 },
  "txstart",
  { data_type => "integer", is_nullable => 1 },
  "txend",
  { data_type => "integer", is_nullable => 1 },
  "strand",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 genome

Type: belongs_to

Related object: L<FoxPrimer::Schema::Result::Genome>

=cut

__PACKAGE__->belongs_to(
  "genome",
  "FoxPrimer::Schema::Result::Genome",
  { id => "genome" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-03-01 16:22:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zCagT91zOqcditqdVg6fzw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
