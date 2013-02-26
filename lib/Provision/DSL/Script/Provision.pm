package Provision::DSL::Script::Provision;
use Moo;
use Path::Class;
use Cwd;
use IPC::Run3;
use Config;
use Hash::Merge 'merge';
use Try::Tiny;
use Time::HiRes qw(gettimeofday tv_interval);
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
            ssh             => SSH,
            ssh_options     => ['-C'],
            cpanm           => CPANM,
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

          # maybe add some options transported to remote via
          #     -o option,option,...
          #
          # options => {
          #     modify_sudoers => 1, # append '$user ALL=(ALL) NOPASSWD: ALL'
          # },

            environment => {
                PROVISION_RSYNC         => RSYNC,
                PROVISION_RSYNC_PORT    => RSYNC_PORT,
                PROVISION_PERL          => PERL,
                PROVISION_HTTP_PORT     => HTTP_PORT,
              # PERL_CPANM_OPT          => "--mirror http://localhost:${\HTTP_PORT} --mirror-only",
            },
        },

        resources => [],
    };
}

has config_file => (
    is        => 'ro',
    coerce    => to_File,
    predicate => 1,
);

has config => (
    is => 'lazy',
);

sub _build_config {
    my $self = shift;

    my $config_from_file = $self->has_config_file
        ? do "${\$self->config_file}"
        : {};
    
    die 'Your config file does not look valid. It must return a Hash-Ref'
        if ref $config_from_file ne 'HASH';

    my $config = merge $config_from_file, default_config;

    push @{$config->{local}->{ssh_options}},
        '-R', "$config->{local}->{cpan_http_port}:127.0.0.1:$config->{remote}->{environment}->{PROVISION_HTTP_PORT}",
        '-R', "$config->{local}->{rsync_port}:127.0.0.1:$config->{remote}->{environment}->{PROVISION_RSYNC_PORT}";

    foreach my $arg (@{$self->args}) {
        if (-f $arg) {
            $self->provision_file($arg);
        } elsif ($arg =~ m{\A (.*) @ (.+) \z}xms) {
            $self->hostname($2);
            $self->user($1) if $1;
        }
    }

    # manually merge in some things entered via commandline
    $config->{remote}->{hostname} = $self->hostname       if $self->has_hostname;
    $config->{remote}->{user}     = $self->user           if $self->has_user;
    $config->{provision_file}     = $self->provision_file if $self->has_provision_file;
    $config->{name}             ||= $config->{provision_file} &&
                                    $config->{provision_file} =~ m{(\w+) [.] \w+ \z}xms
                                        ? $1
                                        : 'default';
    $config->{name}              =~ s{\W+}{_}xmsg;
    $config->{provision_file}   ||= 'provision.pl';

    return $config;
}

# allow to override config
has hostname => (
    is        => 'rw',
    predicate => 1,
);

# allow to override config
has user => (
    is        => 'rw',
    predicate => 1,
);

# allow to override config
has provision_file => (
    is        => 'rw',
    predicate => 1,
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
            if -f $dir->file('Makefile.PL') || -f $dir->file('dist.ini');
        $dir = $dir->parent;
    }

    return dir('/tmp');
}

has cache_dir => (
    is     => 'lazy',
    coerce => to_ExistingDir,
);

sub _build_cache_dir {
    my $self = shift;

    my $cache_dir_name = join '_', '.provision', $self->config->{name} || ();
    my $dir = $self->root_dir->subdir($cache_dir_name);

    $_->mkpath for grep { !-d }
                   map { $dir->subdir($_) }
                   qw(. bin lib log resources);

    return $dir;
}

has resources_dir => (
    is     => 'lazy',
    coerce => to_ExistingDir,
);

sub _build_resources_dir { $_[0]->cache_dir->subdir('resources') }

has rsyncd_config_file => (
    is     => 'lazy',
    coerce => to_File
);

sub _build_rsyncd_config_file {
    my $self = shift;

    my $config_file = $self->cache_dir->file('rsyncd.conf');

    $config_file->spew(<<EOF);
use chroot = no
[local]
    path = ${\$self->cache_dir}
    read only = true
[log]
    path = ${\$self->cache_dir}/log
    read only = false
EOF

    return $config_file;
}

has rsync_daemon => (
    is => 'lazy',
);

sub _build_rsync_daemon {
    my $self = shift;

    return Provision::DSL::Script::Daemon->new(
        RSYNC,
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

has started => (
    is      => 'ro',
    default => sub { [gettimeofday] },
);

sub elapsed { tv_interval($_[0]->started, [gettimeofday]) }

around options => sub {
    my ($orig, $self) = @_;

    return (
        $self->$orig,
        'config_file|c=s    ; specify a config file',
        'root_dir|r=s       ; root dir for locating files and resources',
        'hostname|H=s       ; hostname for ssh, overrides config setting',
        'user|u=s           ; user for ssh, overrides config setting',
        'provision_file|p=s ; provision file to run, overrides config setting',
      # 'options|o=s        ; comma separated options [modify_sudoers, TODO:more]'
      # 'force|f            ; force every entity to execute',
      # 'install_key|i=s'   ; put .pub key into ~/.ssh/authorized_keys
    );
};

sub usage_text { '[[user]@hostname] [provision_file.pl]' }

sub run {
    my $self = shift;

    $self->log('Starting Provisioning');

    $self->log_debug('root_dir =', $self->root_dir);
    $self->log_debug(Data::Dumper->Dump([$self->config], ['config']));

    $self->prepare_environment;
    $self->pack_requisites;
    
    my $result = $self->remote_provision;

    $self->log(
        sprintf('Finished in %0.1fs', $self->elapsed),
        ($result
            ? "Status-Code: $result"
            : ()),
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

    my $installer_file = $self->cache_dir->file(PERLBREW_INSTALLER);
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
        Module::Pluggable Module::Load
        MRO::Compat Class::C3 Algorithm::C3
        HTTP::Tiny Template::Simple
        Path::Class File::Zglob
    );

    foreach my $lib (@install_libs) {
        my $lib_filename = "lib/perl5/$lib.pm";
        $lib_filename =~ s{::}{/}xmsg;
        $self->log_debug("checking for lib file '$lib_filename'");
        next if -f $self->cache_dir->file($lib_filename);

        $self->log_debug("packing lib '$lib' into ${\$self->cache_dir}");
        run3 [
                $self->config->{local}->{cpanm},
                -L => $self->cache_dir, '--notest',
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
        $_ => 'lib/perl5/Provision/',
        [ '*.pod' ],
    ) for $provision_dsl_dir->children;
}

sub _pack_file_or_dir {
    my $self     = shift;
    my $source   = shift;
    my $target   = shift;
    my @exclude  = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
    
    # rsync fails when trying to copy something to a destionation
    # with missing parent directory. Must create the parent directory
    # for the entity to get copied
    my $target_dir = $self->cache_dir->file($target)->parent;
    $target_dir->mkpath if !-d $target_dir;

    # Caution: $target might contain a trailing '/'.
    #          therefore we must join strings instead of ->subdir()
    run3 [
        $self->config->{local}->{rsync},
        '--checksum', '--recursive', '--perms', '--delete',
        ( map { ('--exclude' => $_) } @exclude ),
        $source => join('/', $self->cache_dir, $target),
    ];
}

sub pack_provision_script {
    my $self = shift;

    my $provision_file_name = $self->config->{provision_file} || 'provision.pl';
    my $cache_dir = $self->root_dir->file($provision_file_name)->dir;
    my $provision_script = scalar $self->root_dir->file($provision_file_name)->slurp;

    $provision_script =~ s{^ \s*
                           [Ii]nclude\s+            # 'include' keyword
                           (\w+)                    # $1: file to include
                           (?: \s* , \s* (.+?) )?   # $2: optional arglist
                           \s* ; \s*                # closing semicolon
                           (?: [#] .*? )?           # optional comment
                           $
                           }{$self->_include($cache_dir->file("$1.pl"), $2)}exmsg;

    $self->log(" - packing provision script '$provision_file_name'");
    # warn $provision_script; die 'stop for testing';
    $self->must_have_valid_syntax($provision_script);

    $self->cache_dir->file('provision.pl')->spew($provision_script);
}

sub must_have_valid_syntax {
    my ($self, $script) = @_;

    $self->log_debug('Syntax-Checking combined provision script');

    my $perl = $Config{perlpath} || 'perl';

    my $stderr;
    run3 [$perl, '-c', '-'], \$script, \undef, \$stderr;
    die "Error Checking provision script:\n$stderr" if $? >> 8;
}

sub _include {
    my $self = shift;
    my $file = shift;
    my $args = shift || '';

    my @content;
    my @variables = (eval $args); # keep order of variables
    while (my ($name, $value) = splice @variables, 0, 2) {
        push @content, 'our ' . Data::Dumper->Dump([$value], [$name]);
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

    my $source_path = dir($resource->{source});
    my $source = $source_path->is_absolute
        ? $source_path
        : $self->root_dir->subdir($source_path);
    $source .= '/' if -d $source;

    my $target = 'resources/' . ($resource->{destination} || $resource->{source});

    $self->_pack_file_or_dir(
        $source => $target,
        $resource->{exclude} || [],
    );
}

# remaining args are passed thru to run3 for testing purposes
sub remote_provision {
    my $self = shift;

    my $local       = $self->config->{local};
    my $remote      = $self->config->{remote};
    my $dir_name    = $self->cache_dir->basename;

    # Hint: quoted '$VARIABLES' below are expanded on the remote machine!

    my @command_and_args = (
        $local->{ssh},
        @{$local->{ssh_options}},
        ($remote->{user} ? (-l => $remote->{user}) : ()),

        $remote->{hostname},

        qq{export dir="\$HOME/$dir_name";},
        qq{export PERL5LIB="\$dir/lib/perl5";},
        
        (
            map { qq{export $_="$remote->{environment}->{$_}";} }
            keys %{$remote->{environment}}
        ),

        # Hint: rsync implicitly does mkdir -p $provision_dir
        '(',
        '$PROVISION_RSYNC',
            '-cr',
            '--perms',
            '--delete',
            '--exclude', '"/lib/**.pod"',
            '--exclude', "/lib/perl5/${\$self->archname}",
            '--exclude', '/rsyncd.conf',
            '--exclude', '/log',
            'rsync://127.0.0.1:$PROVISION_RSYNC_PORT/local' => '$dir/',

        '&&',

        '$PROVISION_PERL', '$dir/provision.pl',
            ($self->dryrun  ? ' -n' : ()),
            ($self->verbose ? ' -v' : ()),
            '-l', '$dir/log',
            '-U', '"' . ((getpwuid($<))[6]) . '"',
            # TODO: add more options
        ');',
        
        'status=$?;',

        '$PROVISION_RSYNC',
            '-cr',
            '--delete',
            '$dir/log/' => 'rsync://127.0.0.1:$PROVISION_RSYNC_PORT/log/;',
        
        'exit $status'
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
