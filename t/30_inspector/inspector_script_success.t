use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
require "$FindBin::Bin/../inc/mock_entity.pm";

use ok 'Provision::DSL::Inspector::ScriptSuccess';

my $bin = -f '/usr/bin/true'
    ? '/usr/bin'
    : '/bin';

my @testcases = (
    {
        path => "$bin/false",
        state => 'outdated',
    },
    {
        path => "$bin/true",
        state => 'current',
    },
);

foreach my $testcase (@testcases) {
    my $e = E->new(path => $testcase->{path});
    my $i = Provision::DSL::Inspector::ScriptSuccess->new(entity => $e);
    
    is $i->state, $testcase->{state}, "$testcase->{path}: state is $testcase->{state}";
}

done_testing;
