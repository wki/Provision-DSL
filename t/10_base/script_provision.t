use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use Path::Class;
use IPC::Run3;
use List::Util 'sum';
use Config;

use ok 'Provision::DSL::Script::Provision';

# empty dir created during test
system '/bin/rm', '-rf', "$FindBin::Bin/../../.provision_testing";

# packing a script from a config
{
    my $s = Provision::DSL::Script::Provision->new(
        config_file => "$FindBin::Bin/../conf/test_config.pl",
    );

    is_deeply $s->config,
        {
            name => 'testing',
            provision_file => 't/conf/include_test.pl',

            local => {
                ssh             => 'ssh',
                ssh_options     => [
                    '-q', '-x',
                    '-C',
                    '-R', '2080:127.0.0.1:2080',
                    '-R', '2873:127.0.0.1:2873',
                ],
                cpanm           => 'cpanm',
                cpanm_options   => [],
                rsync           => 'rsync',
                rsync_port      => 2873,
                rsync_modules   => {},
                cpan_http_port  => 2080,
                environment     => {
                    foo => 42,
                    bar => 'some thing',
                },
            },

            remote => {
                hostname        => 'box',

                environment => {
                    PROVISION_RSYNC         => 'rsync',
                    PROVISION_RSYNC_PORT    => 2873,
                    PROVISION_PERL          => 'perl',
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
        config_file => "$FindBin::Bin/../conf/test_config.pl",
    );

    foreach my $key (qw(foo bar)) {
        ok !exists $ENV{$key}, "env key '$key' does not exist";
    }

    $s->prepare_environment;

    foreach my $key (qw(foo bar)) {
        ok exists $ENV{$key}, "env key '$key' exists";
    }
}

# pack a few things and check packed content
{
    no warnings 'redefine';
    no strict 'refs';
    local *{"Provision::DSL::Script::Provision::http_get"} =
        sub { $_[1] };

    my $cache_dir = dir("$FindBin::Bin/../../.provision_testing");
    my $s = Provision::DSL::Script::Provision->new(
        config_file => "$FindBin::Bin/../conf/test_config.pl",
        root_dir    => "$FindBin::Bin/../..",
    );
    $s->config->{local}->{cpanm} = "$FindBin::Bin/../bin/fake_cpanm.pl";

    my $perlbrew_installer = $cache_dir->file("provision/bin/install.perlbrew.sh");
    ok !-f $perlbrew_installer, 'perlbrew installer not present before';
    $s->pack_perlbrew_installer;
    ok -f $perlbrew_installer, 'perlbrew installer loaded';

    my $lib_dir = $cache_dir->subdir('provision/lib/perl5');
    ok !-d $lib_dir, 'lib dir not present before packing';
    $s->pack_dependent_libs;
    $s->pack_provision_libs;
    my $nr_lib_files = $lib_dir->traverse(\&count_files);
    ok $nr_lib_files > 50, "we have > 50 ($nr_lib_files) library files";
    
    my $resource_dir = $cache_dir->subdir('resources');
    $s->pack_resources;
    foreach my $file (qw(files/dir1/dir2/file3.txt
                         files/dir1/file1.txt
                         files/dir1/file2.txt))
    {
        ok -f $resource_dir->file($file), "Resource '$file' exists";
    }
    
    ok !-d $resource_dir->subdir('files/dirx'), 'dirx excluded from resources';

    $s->pack_provision_script;
    my $provision_file = $cache_dir->file('provision/provision.pl');
    ok -f $provision_file, 'provision_file is generated';
    
    is scalar $provision_file->slurp, <<'EOF', 'provision file looks good';
#!/usr/bin/env perl

my $x = 42;
my $site = 'live';

my $dir = '/path/to/x';
Done;
EOF
}


# simulate a provisining on another machine if reachable (box)
SKIP:
{
    system "ssh box echo asdf>/dev/null";

    skip 'cannot ssh to a machine named "box"', 12
        if $? >> 8;

    my $s = Provision::DSL::Script::Provision->new(
        config_file => "$FindBin::Bin/../conf/test_config.pl",
        # will create an rsyncd.conf file inside here and refer
        # to resources/ and provision/ directories
        cache_dir   => "$FindBin::Bin/..",
        archname    => 'xtest-arch'
    );

    my ($stdout, $stderr);
    is $s->remote_provision(\undef, \$stdout, \$stderr),
        13,
        'return status from provision script is given back';
    ok !$stderr, 'stderr is empty';
    
    # diag "STDOUT: $stdout";
    
    my @forbidden_lines = (
        qr{\Q./lib/perl5/Foo.pod\E},
        qr{\Q./lib/perl5/xtest-arch/Bar.pm\E},
    );
    
    my @expected_lines = (
        qr{\Q./lib/perl5/Foo.pm\E},
        qr{PERL5LIB:\s*/tmp/provision_[^/]+/lib/perl5},
        qr{PERL_CPANM_OPT:\s*--mirror\s+http://localhost:2080\s+--mirror-only},
        qr{PROVISION_HTTP_PORT:\s*2080},
        qr{PROVISION_PERL:\s*/usr/bin/perl},
        qr{PROVISION_RSYNC:\s*/usr/bin/rsync},
        qr{PROVISION_RSYNC_PORT:\s*2873},
        qr{XX42:\s*foo},
    );
    
    foreach my $does_not_have (@forbidden_lines) {
        my $text = "$does_not_have";
        $text =~ s{\A [(?^:]+ | [)]\z}{}xmsg;
        $text =~ s{\\/}{/}xmsg;
        $text =~ s{\\s[+*]}{ }xmsg;
        substr($text,31) = '...' if length $text > 30;
        
        unlike $stdout, qr{^$does_not_have$}xms, "stdout does not contain '$text'";
    }
    
    foreach my $must_have (@expected_lines) {
        my $text = "$must_have";
        $text =~ s{\A [(?^:]+ | [)]\z}{}xmsg;
        $text =~ s{\\/}{/}xmsg;
        $text =~ s{\\s[+*]}{ }xmsg;
        substr($text,31) = '...' if length $text > 30;
        
        like $stdout, qr{^$must_have$}xms, "stdout contains '$text'";
    }

    unlink "$FindBin::Bin/../rsyncd.conf";
}


done_testing;


sub count_files {
    my ($child, $cont) = @_;
    return sum $cont->(), -f $child ? 1 : 0
}
