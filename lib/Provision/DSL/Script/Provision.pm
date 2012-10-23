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
            rsync           => '/usr/bin/rsync',
            rsync_port      => 2873,
            rsync_modules   => {},
            cpan_http_port  => 2080,
            environment     => {},
        },

        remote => {
          # hostname        => 'box',
          # user            => 'wolfgang',

            environment => {
                PROVISION_RSYNC         => '/usr/bin/rsync',
                PROVISION_RSYNC_PORT    => 2873,
                PROVISION_PERL          => '/usr/bin/perl',
                PROVISION_HTTP_PORT     => 2080,
                PERL_CPANM_OPT          => '--mirror http://localhost:2080 --mirror-only',
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
                '--port', 2873,
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

    $self->log('Finished Provisioning');
    exit $? >> 8; ### FIXME: get remote provision status somehow.
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
        autodie Moo Role::Tiny Try::Tiny
        HTTP::Tiny Path::Class Template::Simple
        IPC::Run3
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

    # $self->_pack_file_or_dir(
    #     $self->cache_dir,
    #     '.' => '.',
    #     [ $Config{archname}, '*.pod' ], # exclude binary-dir and documentation
    # );
}

sub pack_provision_libs {
    my $self = shift;

    $self->log(' - packing provision libs');

    # Provision::DSL libs are collected manually for two reasons:
    #   - we do not catch dependencies for the controlling machine
    #   - if add-ons are present, we get them, too
    my $this_file = file(__FILE__)->resolve->absolute;
    my $provision_dsl_install_dir = $this_file->dir->parent->parent->parent;

    $self->_pack_file_or_dir(
        $provision_dsl_install_dir,
        'Provision' => 'provision/lib/perl5/Provision',

        [ '*.pod' ], # exclude documentation
    );
}

# ->_pack_file_or_dir ( $root, $rel_source, $rel_target [, \%options] [, \@exclude | @exclude])
sub _pack_file_or_dir {
    my $self = shift;
    my $root_dir = shift;
    my $source = shift;
    my $target = shift;

    my %options = ref $_[0] eq 'HASH' ? %{+shift} : ();

    my @exclude_globs = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
    push @exclude_globs, '.provision_lib';

    my @exclude_regexes =
        map {
            s{\A (?=[^/])}{(\\A|/)}xms; # start of a file name
            s{\A /}{\\A}xms;            # leading / => begin of string
            s{[*][*]}{.*}xmsg;          # ** => anything including /
            s{[*]}{[^/]*}xmsg;          # * => anything but /
            s{[?]}{[^/]}xmsg;           # ? => one char but not /
            s{[.]}{\\.}xmsg;            # . => escaped .
            s{/ \z}{}xms;               # trailing / => ignore

            qr{$_ (/|\z)}xms;
        }
        @exclude_globs;

    $self->log_debug('Exclude Regexes:', @exclude_regexes);

    my $cwd = getcwd;
    chdir $root_dir;

    my $thing_to_pack = $root_dir->subdir($source);
    if (-d $thing_to_pack) {
        $self->__pack_dir($thing_to_pack => $target, \%options, \@exclude_regexes);
    } else {
        $self->__pack_file($root_dir->file($source) => $target, \%options);
    }

    chdir $cwd;
}

sub __pack_dir {
    my ($self, $dir, $dest_dir, $options, $exclude_regexes) = @_;

    $dir->traverse( sub {
        my ($child, $cont) = @_;

        my $relative_file_name = $child->relative($dir)->stringify;
        my $dest_path = $dest_dir
            ? "$dest_dir/$relative_file_name"
            : $relative_file_name;

        if ($relative_file_name eq '.') {
            # ignore .
        } elsif (grep { $relative_file_name =~ $_ } @$exclude_regexes) {
            $self->log_debug('ignoring:', $relative_file_name);
        } elsif (-d $child) {
            $self->log_debug('adding DIR:', $dest_path);
            # $self->cache_dir->subdir($dest_path)->mkpath;
            # $self->tar->add_data(
            #     $dest_path,
            #     '',
            #     { type => DIR, mode => 0755, %$options },
            # );
        } else {
            $self->log_debug('adding FILE:', $relative_file_name, $dest_path);
            $self->__pack_file($child => $dest_path, $options);
        }
        return $cont->();
    });

}

sub __pack_file {
    my ($self, $source_file, $relative_dest_path, $options) = @_;

    my $dest_file = $self->cache_dir->file($relative_dest_path);
    $dest_file->dir->mkpath if !-d $dest_file->dir;
    $dest_file->spew(scalar $source_file->slurp);

    # $self->tar->add_data(
    #     $dest_file,
    #     scalar $file->slurp,
    #     { type => FILE, mode => 0644, %$options },
    # );
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

    my $resource_subdir =
        $resource->{destination}
        // $resource->{source}
        // '';
    my $options = {
        map { exists $resource->{$_} ? ( $_ => $resource->{$_}) : () }
        qw(uid gid)
    };

    $self->log_debug('EXCLUDE:', $resource->{exclude});
    $self->_pack_file_or_dir(
        $self->root_dir,
        $resource->{source} => "resources/$resource_subdir",
        $options,
        $resource->{exclude} // [],
    );
}

sub remote_provision {
    my $self = shift;

    my $local  = $self->config->{local};
    my $remote = $self->config->{remote};
    
    my $user_prefix = exists $remote->{user}
        ? "$remote->{user}\@"
        : '';

    my $temp_dir = File::Temp::tempnam('/tmp', 'provision_');

    my %remote_env = (
        PERL5LIB => "$temp_dir/lib/perl5",
        %{$remote->{environment}},
    );

    my @command_and_args = (
        #
        # establish an ssh connection with compression
        #
        $local->{ssh},
        @{$local->{ssh_options}},

        "$user_prefix$remote->{hostname}",

        ( map { "export $_='$remote_env{$_}'; " } keys %remote_env ),

        '/bin/rm', '-rf', '/tmp/provision_*',

        '&&',

        '/bin/mkdir', '-p', $temp_dir,

        '&&',

        '$PROVISION_RSYNC', '-r',
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

    run3 \@command_and_args;

    $self->rsync_daemon->stop;
}

1;
