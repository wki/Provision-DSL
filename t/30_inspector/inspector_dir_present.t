use strict;
use warnings;
use Test::More;
use FindBin;
require "$FindBin::Bin/../inc/mock_entity.pm";

use ok 'Provision::DSL::Inspector::DirPresent';

my @testcases = (
    { path => '/not/existing/path',     state => 'missing',  need_privilege => 1 },
    { path => '/bin',                   state => 'current',  need_privilege => 1 },
    { path => "$FindBin::Bin",          state => 'current',  need_privilege => 0 },
    { path => "$FindBin::Bin/nonsense", state => 'missing',  need_privilege => 0 },
);

foreach my $testcase (@testcases) {
    my $e = E->new(path => $testcase->{path});
    my $i = Provision::DSL::Inspector::DirPresent->new(entity => $e);
    
    is $i->state, $testcase->{state}, 
        "$testcase->{path}: state is $testcase->{state}";
    is $i->need_privilege ? 1 : 0, $testcase->{need_privilege},
        "$testcase->{path}: need_privilege is $testcase->{need_privilege}";
}

done_testing;
