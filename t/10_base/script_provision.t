use Test::More;
use Test::Exception;
use FindBin;
use Path::Class;

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
        root_dir => "$FindBin::Bin/../conf",
    );
    
    # idea: provision script lists all files in its current dir.
    
    
}

### TODO: more test:
# ensure_perlbrew_installer_loaded
# pack_dependent_libs
# pack_provision_libs
# pack_provision_script
# pack_resources
# check if tar is packed right

done_testing;
