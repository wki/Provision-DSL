use strict;
use warnings;
use Test::More;
use FindBin;
use Path::Class;
require "$FindBin::Bin/../inc/mock_entity.pm";

use ok 'Provision::DSL::Installer::MkDir';

my @testcases = (
    {
        name => 'empty with parent',
        dir => 'foo/bar',
    },
    {
        name => 'file exists',
        dir => 'bar',
    },
    {
        name => 'file-link exists',
        dir => 'baz',
    },
    {
        name => 'dir-link exists',
        dir => 'bat',
    },
);

prepare_dir();

foreach my $testcase (@testcases) {
    my $e = E->new(path => dir("$FindBin::Bin/xxx/$testcase->{dir}"));
    my $i = Provision::DSL::Installer::MkDir->new(entity => $e);

    # ok !-d $e->path, "dir '$testcase->{dir} missing";
    $i->create;
    ok -d $e->path, "dir '$testcase->{dir} successfully created";
}

clean_dir();

done_testing;

sub clean_dir {
    system '/bin/rm', '-rf', "$FindBin::Bin/xxx";
}

sub prepare_dir {
    clean_dir();
    system '/bin/mkdir', '-p', "$FindBin::Bin/xxx";
    system '/usr/bin/touch',   "$FindBin::Bin/xxx/bar";
    system '/usr/bin/touch',   "$FindBin::Bin/xxx/zzz";
    system '/bin/ln', '-s',    "$FindBin::Bin/xxx/zzz", "$FindBin::Bin/xxx/baz";
    system '/bin/ln', '-s',    "$FindBin::Bin/xxx/bar", "$FindBin::Bin/xxx/bat";
}
