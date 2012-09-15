use strict;
use warnings;
use Test::More;
use FindBin;
use Path::Class;
require "$FindBin::Bin/../inc/mock_entity.pm";

use ok 'Provision::DSL::Installer::Touch';

my @testcases = (
    {
        name => 'file exists',
        file => 'bar',
    },
    {
        name => 'file-link exists',
        file => 'baz',
    },
    {
        name => 'dir-link exists',
        file => 'bat',
    },
    {
        name => 'new',
        file => 'bay',
    },
);

prepare_dir();

foreach my $testcase (@testcases) {
    my $e = E->new(path => file("$FindBin::Bin/xxx/$testcase->{file}"));
    my $i = Provision::DSL::Installer::Touch->new(entity => $e);

    $i->create;
    ok -f $e->path && !-d $e->path && !-l $e->path, 
        "file '$testcase->{file} successfully created";
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
