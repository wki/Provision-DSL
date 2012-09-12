use strict;
use warnings;
use Test::More;
use FindBin;
require "$FindBin::Bin/../inc/mock_entity.pm";

use ok 'Provision::DSL::Inspector::Never';

my $e = E->new;
my $i = Provision::DSL::Inspector::Never->new(entity => $e);

is $i->state, 'current', 'Never reports current as state';

done_testing;
