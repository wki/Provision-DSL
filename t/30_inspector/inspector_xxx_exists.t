use strict;
use warnings;
use Test::More;
use Path::Class;
use FindBin;
require "$FindBin::Bin/../inc/mock_entity.pm";

use ok 'Provision::DSL::Inspector::PathExists';
use ok 'Provision::DSL::Inspector::DirExists';
use ok 'Provision::DSL::Inspector::FileExists';
use ok 'Provision::DSL::Inspector::LinkExists';

my $tempdir = Path::Class::tempdir(CLEANUP => 1);

# PathExists
{
    my @testcases = (
        { path => '/not/existing/path',     state => 'missing' },
        { path => '/bin',                   state => 'current' },
        { path => "$tempdir",               state => 'current' },
        { path => $tempdir,                 state => 'current' },
        { path => "$tempdir/nonsense",      state => 'missing' },
    );

    clean_dir();
    run_testcases(PathExists => @testcases);
}

# DirExists
{
    my @testcases = (
        { path => "$tempdir",     state => 'current' },
        { path => "$tempdir/foo", state => 'current' },
        { path => "$tempdir/bar", state => 'missing' },
        { path => "$tempdir/baz", state => 'missing' },
    );

    prepare_dir();
    run_testcases(DirExists => @testcases);
}

# FileExists
{
    my @testcases = (
        { path => "$tempdir/foo", state => 'missing' },
        { path => "$tempdir/bar", state => 'current' },
        { path => "$tempdir/baz", state => 'missing' },
    );

    prepare_dir();
    run_testcases(FileExists => @testcases);
}

# LinkExists
{
    my @testcases = (
        { path => "$tempdir/foo", state => 'missing' },
        { path => "$tempdir/bar", state => 'missing' },
        { path => "$tempdir/baz", state => 'current', link_to => "$tempdir/bar"},
    );

    prepare_dir();
    run_testcases(LinkExists => @testcases);
}

clean_dir();
done_testing;

sub clean_dir {
    system '/bin/rm', '-rf', "$tempdir/*";
}

sub prepare_dir {
    clean_dir();
    system '/bin/mkdir', '-p', "$tempdir/foo";
    system '/usr/bin/touch',   "$tempdir/bar";
    system '/bin/ln', '-s',    "$tempdir/bar", "$tempdir/baz";
}

sub run_testcases {
    my $class_name = shift;

    foreach my $testcase (@_) {
        my $e = E->new();
        #     path => dir($testcase->{path}),
        #     # ($testcase->{link_to} ? (link_to => dir($testcase->{link_to})): ())
        # );
        my $class = "Provision::DSL::Inspector::$class_name";
        my $i = $class->new(entity => $e, expected_value => $testcase->{path});

        is $i->state, $testcase->{state},
            "$class_name - $testcase->{path}: state is $testcase->{state}";
    }
}
