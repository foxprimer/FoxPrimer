package FoxPrimer::Model::Valid_mRNA;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'FoxPrimer::Schema',
    
    connect_info => {
        dsn => 'dbi:SQLite:db/gene2accession.db',
        user => '',
        password => '',
    }
);

=head1 NAME

FoxPrimer::Model::Valid_mRNA - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<FoxPrimer>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<FoxPrimer::Schema>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema - 0.59

=head1 AUTHOR

Jason R Dobson

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
