package FoxPrimer::Model::PeaksToGenes::FileStructure;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PeaksToGenes::FileStructure - Catalyst Model

=head1 DESCRIPTION

This module provides a subroutine, which takes the genome as an
argument and returns an Array Ref of file locations for each
index.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



__PACKAGE__->meta->make_immutable;

1;
