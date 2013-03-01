package FoxPrimer::View::Web;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

=head1 NAME

FoxPrimer::View::Web - TT View for FoxPrimer

=head1 DESCRIPTION

TT View for FoxPrimer.

=head1 SEE ALSO

L<FoxPrimer>

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
