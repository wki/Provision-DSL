use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
require "$FindBin::Bin/../inc/mock_entity.pm";

use ok 'Provision::DSL::Inspector::ScriptSuccess';

my @testcases = (
    {
        name   => 'false',
        script => 'false',
        state  => 'outdated',
    },
    {
        name   => 'true',
        script => 'true',
        state  => 'current',
    },
    {
        name   => '[false]',
        script => ['false'],
        state  => 'outdated',
    },
    {
        name   => '[true]',
        script => ['true'],
        state  => 'current',
    },
    {
        name   => 'sh exit 1',
        script => ['sh', '-c', 'exit 1'],
        state  => 'outdated',
    },
);

foreach my $testcase (@testcases) {
    my $e = E->new();
    my $i = Provision::DSL::Inspector::ScriptSuccess->new(
        entity => $e,
        expected_value => $testcase->{script},
    );
    
    is $i->state, $testcase->{state}, "$testcase->{name}: state is $testcase->{state}";
}

done_testing;
