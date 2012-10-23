use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use Path::Class;
use IPC::Run3;

use ok 'Provision::DSL::Script::Provision';

# empty dir created during test
system '/bin/rm', '-rf', "$FindBin::Bin/../../.provision_testing";

# packing a script from a config
{
    my $s = Provision::DSL::Script::Provision->new(
        config => "$FindBin::Bin/../conf/test_config.pl",
    );

    is_deeply $s->config,
        {
            name => 'testing',
            provision_file => 't/conf/list_files.pl',
            
            local => {
                ssh             => '/usr/bin/ssh',
                ssh_options     => [
                    '--foo', 42, '--bar', 'zzz',
                    '-C',
                    '-R', '2080:127.0.0.1:2080',
                    '-R', '2873:127.0.0.1:2873',
                ],
                cpanm           => 'cpanm',
                cpanm_options   => [],
                rsync           => '/usr/bin/rsync',
                rsync_port      => 2873,
                rsync_modules   => {},
                cpan_http_port  => 2080,
                environment     => {
                    foo => 42,
                    bar => 'some thing',
                },
            },
            
            remote => {
                hostname        => 'localhost',
                user            => 'nobody',
            
                environment => {
                    PROVISION_RSYNC         => '/usr/bin/rsync',
                    PROVISION_RSYNC_PORT    => 2873,
                    PROVISION_PERL          => '/usr/bin/perl',
                    PROVISION_HTTP_PORT     => 2080,
                    PERL_CPANM_OPT          => '--mirror http://localhost:2080 --mirror-only',
                    XX42                    => 'foo',
                },
            },
            
            resources => [
                {
                    source      => 't/resources',
                    destination => 'files',
                    exclude     => 'dirx',
                },
            ],
        },
        'config is merged right';

    isa_ok $s->root_dir, 'Path::Class::Dir';
    is $s->root_dir->absolute->resolve->stringify,
       dir("$FindBin::Bin")->parent->parent->absolute->resolve->stringify,
       'root directory is discovered.';

    is $s->cache_dir->absolute->resolve->stringify,
       dir("$FindBin::Bin")->parent->parent->subdir('.provision_testing')->absolute->resolve->stringify,
       'cache_dir is discovered.';
    ok -d $s->cache_dir, 'cache_dir exists';
    ok -d $s->provision_dir, 'provision_dir exists';
    ok -d $s->resources_dir, 'resources_dir exists';
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
    
    $s->config->{local}->{cpanm} = "$FindBin::Bin/../bin/fake_cpanm.pl";

    $s->pack_perlbrew_installer;
    ok -f "$FindBin::Bin/../../.provision_testing/provision/bin/install.perlbrew.sh",
        'perlbrew installer loaded';
    
    $s->pack_dependent_libs;
    
    $s->pack_provision_libs;
    
    $s->pack_resources;
    
    $s->pack_provision_script;
    
    ### TODO: check file existence

    # my $stdout;
    # my $stderr;
    # run3 [$^X], \$s->script, \$stdout, \$stderr;
    # 
    # # warn $stdout;
    # ok !$stderr, 'no output on STDERR';
    # 
    # like $stdout, qr{^provision[.]pl$}xms,
    #     'provision file inside tar';
    # 
    # ok scalar(grep { m{/Provision/DSL/}xms } split /\n/, $stdout) > 10,
    #     'Provision::DSL files in tar';
    # 
    # ok scalar(grep { m{\Aresources/files/dir1/}xms } split /\n/, $stdout) > 2,
    #     'resources/dir1 files in tar';
    # 
    # ok scalar(grep { m{\Aresources/files/dirx/}xms } split /\n/, $stdout) == 0,
    #     'resources/dirx files excluded';
}

# ensure_perlbrew_installer_loaded
# SKIP:
# {
#     skip 'Not connected to the Internet', 3
#         if !gethostbyname('www.cpan.org');
#     
#     my $s = Provision::DSL::Script::Provision->new(
#         config => "$FindBin::Bin/../conf/test_config.pl",
#         root_dir => "$FindBin::Bin/../..",
#         cache_dir => '/tmp',
#     );
#     
#     system '/bin/rm', '-rf', '/tmp/bin';
#     
#     $s->ensure_perlbrew_installer_loaded;
#     
#     ok -d '/tmp/bin', 'bin directory created';
#     ok -f '/tmp/bin/install.perlbrew.sh', 'perlbrew installer loaded';
#     ok -s '/tmp/bin/install.perlbrew.sh' > 500,
#         'perlbrew installer size looks good';
# }

### TODO: more test:
# pack_dependent_libs

done_testing;
