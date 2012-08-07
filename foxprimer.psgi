use strict;
use warnings;

use FoxPrimer;

my $app = FoxPrimer->apply_default_middlewares(FoxPrimer->psgi_app);
$app;

