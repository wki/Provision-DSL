use strict;
use warnings;
use Test::More;
use Path::Class;
use FindBin;
require "$FindBin::Bin/../inc/mock_entity.pm";

use ok 'Provision::DSL::Inspector::PathAge';

prepare_dir();

my @testcases = (
    { file => 'xxx', compare => 'bar', state => 'missing' },
    { file => 'foo', compare => 'bar', state => 'outdated' },
    { file => 'bar', compare => 'bar', state => 'current' },
    { file => 'baz', compare => 'bar', state => 'current' },
    ### FIXME: compare with missing file needed?
    ### FIXME: compare with empty list of files needed?
);

foreach my $testcase (@testcases) {
    my $e = E->new(path => file("$FindBin::Bin/xxx/$testcase->{file}"));
    my $i = Provision::DSL::Inspector::PathAge->new(
        entity => $e, 
        expected_value => "$FindBin::Bin/xxx/$testcase->{compare}",
    );

    is $i->state, $testcase->{state},
        "$testcase->{file}: state is $testcase->{state}";
}

clean_dir();
done_testing;

sub clean_dir {
    system '/bin/rm', '-rf', "$FindBin::Bin/xxx";
}

sub prepare_dir {
    clean_dir();
    system '/bin/mkdir', '-p', "$FindBin::Bin/xxx";
    system '/usr/bin/touch', '-t', '201203051600', "$FindBin::Bin/xxx/foo"; # oldest
    system '/usr/bin/touch', '-t', '201203051730', "$FindBin::Bin/xxx/bar"; # mid-age
    system '/usr/bin/touch', '-t', '201203051842', "$FindBin::Bin/xxx/baz"; # newest
}
