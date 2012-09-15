use strict;
use warnings;
use Test::More;
use FindBin;
use Path::Class;
require "$FindBin::Bin/../inc/mock_entity.pm";

use ok 'Provision::DSL::Installer::Link';

my @testcases = (
    {
        name => 'file exists',
        file => 'bar',
    },
    {
        name => 'dir-link exists',
        file => 'baz',
    },
    {
        name => 'new',
        file => 'foo',
    },
);

prepare_dir();

foreach my $testcase (@testcases) {
    my $e = E->new(
        path    => file("$FindBin::Bin/xxx/$testcase->{file}"),
        link_to => dir("$FindBin::Bin/xxx/target")
    );
    my $i = Provision::DSL::Installer::Link->new(entity => $e);

    $i->create;
    ok -l $e->path, 
        "link '$testcase->{file} successfully created";
    is readlink $e->path, $e->link_to,
        "link '$testcase->{file} destination ok";
}

clean_dir();

done_testing;

sub clean_dir {
    system '/bin/rm', '-rf', "$FindBin::Bin/xxx";
}

sub prepare_dir {
    clean_dir();
    system '/bin/mkdir', '-p', "$FindBin::Bin/xxx/thing";
    system '/bin/mkdir', '-p', "$FindBin::Bin/xxx/target";
    system '/usr/bin/touch',   "$FindBin::Bin/xxx/bar";
    system '/usr/bin/touch',   "$FindBin::Bin/xxx/zzz";
    system '/bin/ln', '-s',    "$FindBin::Bin/xxx/zzz",   "$FindBin::Bin/xxx/baz";
    system '/bin/ln', '-s',    "$FindBin::Bin/xxx/thing", "$FindBin::Bin/xxx/bat";
}
