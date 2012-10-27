package Provision::DSL::Script::Provision;
use Moo;
use feature ':5.10';
use Path::Class;
use File::Temp ();
use Cwd;
use IPC::Run3;
use Config;
use Hash::Merge 'merge';
use Try::Tiny;
use Proc::Daemon;
use Provision::DSL::Types;
use Provision::DSL::Const;
use Provision::DSL::Script::Daemon;
use Data::Dumper; $Data::Dumper::Sortkeys = 1;

with 'Provision::DSL::Role::CommandlineOptions',
     'Provision::DSL::Role::HTTP';

sub default_config {
    +{
      # name => 'some_name',
      # provision_file => 'relative/path/to/file.pl',

        local => {
            ssh             => '/usr/bin/ssh',
            ssh_options     => ['-C'],
            cpanm           => 'cpanm',         # search via $PATH
            cpanm_options   => [],
            rsync           => RSYNC,
            rsync_port      => RSYNC_PORT,
            rsync_modules   => {},
            cpan_http_port  => HTTP_PORT,
            environment     => {},
        },

        remote => {
          # hostname        => 'box',
          # user            => 'wolfgang',

            environment => {
                PROVISION_RSYNC         => RSYNC,
                PROVISION_RSYNC_PORT    => RSYNC_PORT,
                PROVISION_PERL          => PERL,
                PROVISION_HTTP_PORT     => HTTP_PORT,
                PERL_CPANM_OPT          => "--mirror http://localhost:${\HTTP_PORT} --mirror-only",
            },
        },

        resources => [],
    };
}

has config => (
    is       => 'ro',
    required => 1,
    coerce   => sub {
        my $config = merge do $_[0], default_config;
        
        push @{$config->{local}->{ssh_options}},
            '-R', "$config->{local}->{cpan_http_port}:127.0.0.1:$config->{remote}->{environment}->{PROVISION_HTTP_PORT}",
            '-R', "$config->{local}->{rsync_port}:127.0.0.1:$config->{remote}->{environment}->{PROVISION_RSYNC_PORT}";
        
        return $config;
    },
);

# allow faking arch during tests
has archname => (
    is      => 'ro',
    default => sub { $Config{archname} },
);

has root_dir => (
    is     => 'lazy',
    coerce => to_ExistingDir,
);

sub _build_root_dir {
    my $self = shift;

    my $dir = dir(getcwd);

    while (scalar $dir->dir_list > 1) {
        return $dir
            if -f $dir->file('Makefile.PL') ||
               -f $dir->file('dist.ini');
        $dir = $dir->parent;
    }

    die 'cannot guess root_dir, stopping.';
}

has cache_dir => (
    is     => 'lazy',
    coerce => to_ExistingDir,
);

sub _build_cache_dir {
    my $self = shift;

    my $cache_dir_name = join '_', '.provision', $self->config->{name} // ();
    my $dir = $self->root_dir->subdir($cache_dir_name);
    $dir->mkpath if !-d $dir;

    return $dir;
}

has provision_dir => (
    is     => 'lazy',
    coerce => to_ExistingDir,
);

sub _build_provision_dir {
    my $self = shift;

    my $provision_dir = $self->cache_dir->subdir('provision');
    if (!-d $provision_dir) {
        $provision_dir->mkpath;
        $provision_dir->subdir($_)->mkpath
            for qw(bin lib);
    }
    return $provision_dir;
}

has resources_dir => (
    is     => 'lazy',
    coerce => to_ExistingDir,
);

sub _build_resources_dir {
    my $self = shift;

    my $resources_dir = $self->cache_dir->subdir('resources');
    $resources_dir->mkpath if !-d $resources_dir;
    return $resources_dir;
}

has rsyncd_config_file => (
    is     => 'lazy',
    coerce => to_File
);

sub _build_rsyncd_config_file {
    my $self = shift;

    my $config_file = $self->cache_dir->file('rsyncd.conf');

    $config_file->spew(<<EOF);
use chroot = no
[provision]
    path = ${\$self->provision_dir}
[resources]
    path = ${\$self->resources_dir}
EOF

    return $config_file;
}

has rsync_daemon => (
    is => 'lazy',
);

sub _build_rsync_daemon {
    my $self = shift;

    return Provision::DSL::Script::Daemon->new(
        '/usr/bin/rsync',
        {
            args => [
                '--daemon',
                '--address', '127.0.0.1',
                '--no-detach',
                '--port', $self->config->{local}->{rsync_port},
                '--config', $self->rsyncd_config_file->stringify,
            ],
        }
    );
}

around options => sub {
    my ($orig, $self) = @_;

    return (
        $self->$orig,
        'config|c=s     ; specify a config file (required)',
        'root_dir|r=s   ; root dir for locating files and resources',
    );
};

sub run {
    my $self = shift;

    $self->log('Starting Provisioning');

    $self->log_debug('root_dir =', $self->root_dir);
    $self->log_debug(Data::Dumper->Dump([$self->config], ['config']));

    $self->prepare_environment;
    $self->pack_requisites;

    my $result = $self->remote_provision;

    $self->log(
        'Finished Provisioning',
        ($result
            ? ('Status-Code:', $result)
            : ())
    );
    exit $result;
}

sub prepare_environment {
    my $self = shift;

    return if !exists $self->config->{local}->{environment};

    my %vars = %{$self->config->{local}->{environment}};
    @ENV{keys %vars} = values %vars;

    $self->log_debug(Data::Dumper->Dump([\%ENV, \%vars], ['ENV', 'vars']));
}

sub pack_requisites {
    my $self = shift;

    $self->pack_perlbrew_installer;
    $self->pack_dependent_libs;
    $self->pack_provision_libs;
    $self->pack_resources;
    $self->pack_provision_script;
}

sub pack_perlbrew_installer {
    my $self = shift;

    my $installer_file = $self->provision_dir->file(PERLBREW_INSTALLER);
    return if -f $installer_file;

    $self->log('loading perlbrew installer');

    ### FIXME: does not work.
    ### HTTP::Tiny version 0.017 works when IO::Socket::SSL is installed
    # alternative:
    # curl -L http://install.perlbrew.pl -o .provision_lib/bin/install.perlbrew.sh

    try {
        $installer_file->dir->mkpath;
        my $installer = $self->http_get(PERLBREW_INSTALLER_URL);
        $installer_file->spew($installer);
        chmod 0755, $installer_file;
    } catch {
        die 'Could not load Perlbrew installer. ' .
            'Are you online? Is IO::Socket::SSL installed?';
    };
}

sub pack_dependent_libs {
    my $self = shift;

    $self->log(' - packing dependent libs');

    my @install_libs = qw(
        autodie Moo Role::Tiny Try::Tiny IPC::Run3
        HTTP::Tiny Path::Class Template::Simple
    );

    foreach my $lib (@install_libs) {
        my $lib_filename = "lib/perl5/$lib.pm";
        $lib_filename =~ s{::}{/}xmsg;
        next if -f $self->provision_dir->file($lib_filename);

        run3 [
                $self->config->{local}->{cpanm},
                -L => $self->provision_dir, '--notest',
                @{$self->config->{local}->{cpanm_options}},
                $lib
            ],
            \undef, \undef, \undef;
    }
}

sub pack_provision_libs {
    my $self = shift;

    $self->log(' - packing provision libs');

    # Provision::DSL libs are collected manually for two reasons:
    #   - we do not catch dependencies for the controlling machine
    #   - if add-ons are present, we get them, too
    my $this_file = file(__FILE__)->resolve->absolute;
    
    # points to "Provision/" dir (where Provision::DSL is installed)
    my $provision_dsl_dir = $this_file->dir->parent->parent;

    $self->_pack_file_or_dir(
        $_ => 'provision/lib/perl5/Provision/',
        [ '*.pod' ],
    ) for $provision_dsl_dir->children;
}

sub _pack_file_or_dir {
    my $self     = shift;
    my $source   = shift;
    my $target   = shift;
    my @exclude  = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;

    # Caution: $target might contain a trailing '/'.
    #          therefore we must join strings instead of ->subdir()
    run3 [
        $self->config->{local}->{rsync},
        '--checksum', '--recursive',
        ( map { ('--exclude' => $_) } @exclude ),
        $source => join('/', $self->cache_dir, $target),
    ];
}

sub pack_provision_script {
    my $self = shift;

    my $provision_file_name = $self->config->{provision_file} // 'provision.pl';
    my $provision_dir = $self->root_dir->file($provision_file_name)->dir;
    my $provision_script = scalar $self->root_dir->file($provision_file_name)->slurp;

    $provision_script =~ s{^ \s*
                           [Ii]nclude\s+            # 'include' keyword
                           (\w+)                    # $1: file to include
                           (?: \s* , \s* (.+?) )?   # $2: optional arglist
                           \s* ; \s*                # closing semicolon
                           (?: [#] .*? )?           # optional comment
                           $
                           }{$self->_include($provision_dir->file("$1.pl"), $2)}exmsg;

    $self->log(" - packing provision script '$provision_file_name'");
    # warn $provision_script; die 'stop for testing';
    $self->must_have_valid_syntax($provision_script);

    $self->provision_dir->file('provision.pl')->spew($provision_script);
    # $self->tar->add_data(
    #     'provision.pl',
    #     $provision_script,
    #     { type => FILE, mode => 0755 },
    # );
}

sub must_have_valid_syntax {
    my ($self, $script) = @_;

    $self->log_debug('Syntax-Checking combined provision script');

    my $perl = $Config{perlpath} // 'perl';

    my $stderr;
    run3 [$perl, '-c', '-'], \$script, \undef, \$stderr;
    die "Error Checking provision script:\n$stderr" if $? >> 8;
}

sub _include {
    my $self = shift;
    my $file = shift;
    my $args = shift // '';

    my @content;
    my @variables = (eval $args); # keep order of variables
    while (my ($name, $value) = splice @variables, 0, 2) {
        push @content, 'my ' . Data::Dumper->Dump([$value], [$name]);
    }

    push @content, $file->slurp(chomp => 1);

    return join "\n", @content;
}

sub pack_resources {
    my $self = shift;

    $self->log(' - packing resources');

    my $resources = $self->config->{resources}
        or return;

    if (ref $resources eq 'ARRAY') {
        $self->pack_resource($_) for @$resources;
    } else {
        $self->pack_resource($resources);
    }
}

sub pack_resource {
    my ($self, $resource) = @_;

    my $source = $self->root_dir->subdir($resource->{source});
    $source .= '/' if -d $source;
    
    my $target = 'resources/' . ($resource->{destination} // $resource->{source});

    $self->_pack_file_or_dir(
        $source => $target,
        $resource->{exclude} // [],
    );
}

# remaining args are passed thru to run3 for testing purposes
sub remote_provision {
    my $self = shift;

    my $local    = $self->config->{local};
    my $remote   = $self->config->{remote};
    my $temp_dir = File::Temp::tempnam('/tmp', 'provision_');

    # Hint: quoted '$VARIABLES' below are expanded on the remote machine!
    
    my @command_and_args = (
        $local->{ssh},
        @{$local->{ssh_options}},
        ($remote->{user} ? (-l => $remote->{user}) : ()),

        $remote->{hostname},

        "export PERL5LIB='$temp_dir/lib/perl5';",
        ( 
            map { "export $_='$remote->{environment}->{$_}';" }
            keys %{$remote->{environment}} 
        ),

        # FIXME: is this kind of cleanup wise?
        '/bin/rm', '-rf', '/tmp/provision_*',

        '&&',

        '/bin/mkdir', '-p', $temp_dir,

        '&&',

        '$PROVISION_RSYNC', '-r',
            '--exclude', '"*.pod"',
            '--exclude', "/lib/perl5/${\$self->archname}",
            'rsync://127.0.0.1:$PROVISION_RSYNC_PORT/provision' => "$temp_dir/",

        '&&',

        '$PROVISION_PERL', "$temp_dir/provision.pl",
            ($self->dryrun  ? ' -n' : ()),
            ($self->verbose ? ' -v' : ()),

        # uncomment as soon as things do work
        # '&&'
        # '/bin/rm', '-rf', $temp_dir,
    );

    $self->log(' - running provision script on', $remote->{hostname});
    $self->log_debug('Executing:', @command_and_args);

    $self->rsync_daemon->start;

    run3 \@command_and_args, @_;
    my $status = $? >> 8;

    $self->rsync_daemon->stop;
    
    return $status;
}

1;
