use strict;
use warnings;
use Test::More;
use FindBin;
require "$FindBin::Bin/../inc/mock_entity.pm";

use ok 'Provision::DSL::Inspector::Always';

my $e = E->new;
my $i = Provision::DSL::Inspector::Always->new(entity => $e);

is $i->state, 'outdated', 'Always reports outdated as state';

done_testing;
