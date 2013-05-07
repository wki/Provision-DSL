use strict;
use warnings;
use Test::More;
use Path::Class;
use FindBin;
require "$FindBin::Bin/../inc/mock_entity.pm";

use ok 'Provision::DSL::Inspector::PathAge';

my $tempdir = Path::Class::tempdir(CLEANUP => 1);

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
    my $e = E->new(path => $tempdir->file($testcase->{file}));
    my $i = Provision::DSL::Inspector::PathAge->new(
        entity => $e, 
        expected_value => $tempdir->file($testcase->{compare}),
    );

    is $i->state, $testcase->{state},
        "$testcase->{file}: state is $testcase->{state}";
}

done_testing;

sub prepare_dir {
    system 'touch', '-t', '201203051600', "$tempdir/foo"; # oldest
    system 'touch', '-t', '201203051730', "$tempdir/bar"; # mid-age
    system 'touch', '-t', '201203051842', "$tempdir/baz"; # newest
}
