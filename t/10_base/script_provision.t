use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use Path::Class;
use IPC::Run3;

use ok 'Provision::DSL::Script::Provision';

# packing a script from a config
{
    my $s = Provision::DSL::Script::Provision->new(
        config => "$FindBin::Bin/../conf/test_config.pl",
    );

    is ref($s->config), 'HASH', 'config is a hashref';
    ok exists $s->config->{environment}, 'config->{environment} exists';

    isa_ok $s->root_dir, 'Path::Class::Dir';
    is $s->root_dir->absolute->resolve->stringify,
       dir("$FindBin::Bin")->parent->parent->absolute->resolve->stringify,
       'root directory is discovered.';

    is $s->temp_lib_dir->absolute->resolve->stringify,
       dir("$FindBin::Bin")->parent->parent->subdir('.provision_lib')->absolute->resolve->stringify,
       'temp_lib_dir is discovered.';
    ok -d $s->temp_lib_dir, 'temp_lib_dir exists';

    isa_ok $s->tar, 'Archive::Tar';

    like $s->script,
         qr{\A\#!/usr/bin/env .*
            ^__DATA__.*
            [0-9a-zA-Z]}xms,
         'script contains base64-encoded stuff';
}

# env
{
    my $s = Provision::DSL::Script::Provision->new(
        config => "$FindBin::Bin/../conf/test_config.pl",
    );

    foreach my $key (qw(foo bar)) {
        ok !exists $ENV{$key}, "env key '$key' does not exist";
    }

    $s->prepare_environment;

    foreach my $key (qw(foo bar)) {
        ok exists $ENV{$key}, "env key '$key' exists";
    }
}

# pack a few things and run the script
{
    my $s = Provision::DSL::Script::Provision->new(
        config => "$FindBin::Bin/../conf/test_config.pl",
        root_dir => "$FindBin::Bin/../..",
    );

    $s->pack_provision_libs;
    $s->pack_resources;
    $s->pack_provision_script;

    my $stdout;
    my $stderr;
    run3 [$^X], \$s->script, \$stdout, \$stderr;

    # warn $stdout;
    ok !$stderr, 'no output on STDERR';

    like $stdout, qr{^provision[.]pl$}xms,
        'provision file inside tar';

    ok scalar(grep { m{/Provision/DSL/}xms } split /\n/, $stdout) > 10,
        'Provision::DSL files in tar';

    ok scalar(grep { m{\Aresources/files/dir1/}xms } split /\n/, $stdout) > 2,
        'resources/dir1 files in tar';

    ok scalar(grep { m{\Aresources/files/dirx/}xms } split /\n/, $stdout) == 0,
        'resources/dirx files excluded';
}

### TODO: more test:
# ensure_perlbrew_installer_loaded
# pack_dependent_libs

done_testing;
