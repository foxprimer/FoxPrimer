use utf8;
package FoxPrimer::Model::UCSC;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

=head1 NAME

FoxPrimer::Model::UCSC - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jason R Dobson, L<foxprimer@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
