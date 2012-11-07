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

# PathExists
{
    my @testcases = (
        { path => '/not/existing/path',     state => 'missing' },
        { path => '/bin',                   state => 'current' },
        { path => "$FindBin::Bin",          state => 'current' },
        { path => "$FindBin::Bin/nonsense", state => 'missing' },
    );

    clean_dir();
    run_testcases(PathExists => @testcases);
}

# DirExists
{
    my @testcases = (
        { path => "$FindBin::Bin/xxx",     state => 'current' },
        { path => "$FindBin::Bin/xxx/foo", state => 'current' },
        { path => "$FindBin::Bin/xxx/bar", state => 'missing' },
        { path => "$FindBin::Bin/xxx/baz", state => 'missing' },
    );

    prepare_dir();
    run_testcases(DirExists => @testcases);
}

# FileExists
{
    my @testcases = (
        { path => "$FindBin::Bin/xxx/foo", state => 'missing' },
        { path => "$FindBin::Bin/xxx/bar", state => 'current' },
        { path => "$FindBin::Bin/xxx/baz", state => 'missing' },
    );

    prepare_dir();
    run_testcases(FileExists => @testcases);
}

# LinkExists
{
    my @testcases = (
        { path => "$FindBin::Bin/xxx/foo", state => 'missing' },
        { path => "$FindBin::Bin/xxx/bar", state => 'missing' },
        { path => "$FindBin::Bin/xxx/baz", state => 'current', link_to => "$FindBin::Bin/xxx/bar"},
    );

    prepare_dir();
    run_testcases(LinkExists => @testcases);
}

clean_dir();
done_testing;

sub clean_dir {
    system '/bin/rm', '-rf', "$FindBin::Bin/xxx";
}

sub prepare_dir {
    clean_dir();
    system '/bin/mkdir', '-p', "$FindBin::Bin/xxx/foo";
    system '/usr/bin/touch',   "$FindBin::Bin/xxx/bar";
    system '/bin/ln', '-s',    "$FindBin::Bin/xxx/bar", "$FindBin::Bin/xxx/baz";
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
