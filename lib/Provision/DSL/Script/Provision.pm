package Provision::DSL::Script::Provision;
use Moo;
use feature ':5.10';
use Archive::Tar;
use Archive::Tar::Constant;
use Path::Class;
use IO::String;
use MIME::Base64;
use Cwd;
use IPC::Run ();
use Config;
use Provision::DSL::Types;
use Provision::DSL::Const;
use Data::Dumper; $Data::Dumper::Sortkeys = 1;

#
# test with:
# PERL5LIB=lib bin/provision.pl -c sample_config.pl -n -v --debug
#

with 'Provision::DSL::Role::CommandlineOptions',
     'Provision::DSL::Role::CommandExecution',
     'Provision::DSL::Role::HTTP';

has config => (
    is => 'ro',
    required => 1,
    coerce => sub { do $_[0] },
);

has root_dir => (
    is => 'lazy',
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

has temp_lib_dir => (
    is => 'lazy',
    coerce => to_ExistingDir,
);

sub _build_temp_lib_dir {
    my $self = shift;

    my $dir = $self->root_dir->subdir('.provision_lib');
    $dir->mkpath if !-d $dir;

    return $dir;
}

has tar => (
    is => 'lazy',
);

sub _build_tar { Archive::Tar->new }

has script => (
    is => 'lazy',
);

sub _build_script { $_[0]->_boot_script . $_[0]->_tar_content_base64_encoded }

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

    if ($self->debug) {
        my $fh = file('/tmp/provision.pl')->openw;
        print $fh $self->script;
        $fh->close;
    }

    my $result = $self->remote_execute;

    $self->log('Finished Provisioning');
}

sub prepare_environment {
    my $self = shift;

    return if !exists $self->config->{environment};

    my %vars = %{$self->config->{environment}};
    @ENV{keys %vars} = values %vars;

    $self->log_debug(Data::Dumper->Dump([\%ENV, \%vars], ['ENV', 'vars']));
}

sub pack_requisites {
    my $self = shift;

    $self->ensure_perlbrew_installer_loaded;

    $self->pack_dependent_libs;
    $self->pack_provision_libs;
    $self->pack_resources;
    $self->pack_provision_script;
}

sub ensure_perlbrew_installer_loaded {
    my $self = shift;

    my $installer_file = $self->temp_lib_dir->file(PERLBREW_INSTALLER);
    return if -f $installer_file;

    $self->log_debug('loading perlbrew installer');

    $installer_file->dir->mkpath;
    my $installer = $self->http_get(PERLBREW_INSTALLER_URL);
    my $fh = $installer_file->openw;
    print $fh $installer;
    $fh->close;
    
    chmod 0755, $installer_file;
}

sub pack_dependent_libs {
    my $self = shift;

    my @install_libs = qw(
        autodie Moo Role::Tiny Try::Tiny
        HTTP::Tiny Path::Class Template::Simple
        IPC::Run3
    );

    foreach my $lib (@install_libs) {
        my $lib_filename = "lib/perl5/$lib.pm";
        $lib_filename =~ s{::}{/}xmsg;
        next if -f $self->temp_lib_dir->file($lib_filename);

        $self->system_command(
            'cpanm',
            -L => $self->temp_lib_dir,
            -n => $lib
        );
    }

    $self->_pack_dir(
        $self->temp_lib_dir,
        '.' => "local",
        $Config{archname}
    );
}

sub pack_provision_libs {
    my $self = shift;

    # Provision::DSL libs are collected manually for two reasons:
    #   - we do not catch dependencies for the controlling machine
    #   - if add-ons are present, we get them, too
    my $this_file = file(__FILE__)->resolve->absolute;
    my $provision_dsl_install_dir = $this_file->dir->parent->parent->parent;

    $self->_pack_dir(
        $provision_dsl_install_dir,
        'Provision' => 'local/lib/perl5',
    );
}

sub _pack_dir {
    my $self = shift;
    my $root_dir = shift;
    my $source_subdir_name = shift;
    my $target_subdir_name = shift;

    my @exclude_regexes =
        map {
            s{\A /}{\\A}xms;    # leading / => begin of string
            s{\*\*}{.*}xmsg;    # ** => anything including /
            s{\*}{[^/]*}xmsg;   # * => anything but /
            s{\?}{.}xmsg;       # ? => one char
            s{\.}{\\.}xmsg;     # . => escaped .

            qr{$_}xms;
        }
        ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;

    my $cwd = getcwd;
    chdir $root_dir;

    my $subdir = $root_dir->subdir($source_subdir_name);
    $subdir->traverse( sub {
        my ($child, $cont) = @_;

        my $relative_file_name = $child->relative($root_dir)->stringify;
        my $dest_file = $target_subdir_name
            ? "$target_subdir_name/$relative_file_name"
            : $relative_file_name;

        if ($relative_file_name eq '.') {
            # ignore .
        } elsif (grep { $relative_file_name =~ $_ } @exclude_regexes) {
            $self->log_debug('ignoring:', $relative_file_name);
        } elsif (-d $child) {
            $self->log_debug('adding DIR:', $dest_file);
            $self->tar->add_data(
                $dest_file,
                '',
                { type => DIR, mode => 0755 },
            );
        } else {
            $self->log_debug('adding FILE:', $dest_file);
            $self->tar->add_data(
                $dest_file,
                scalar $child->slurp,
                { type => FILE, mode => 0644 },
            );
        }

       return $cont->();
    });

    chdir $cwd;
}

sub pack_provision_script {
    my $self = shift;

    my $provision_file_name = $self->config->{provision_file} // 'provision.pl';
    my $provision_script = $self->root_dir->file($provision_file_name);

    $self->log_debug("adding provision script '$provision_file_name'");

    $self->tar->add_data(
        'provision.pl',
        scalar $provision_script->slurp,
        { type => FILE, mode => 0755 },
    );
}

sub pack_resources {
    my $self = shift;

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

    my $resource_subdir = $resource->{destination} // '';

    $self->_pack_dir(
        $self->root_dir,
        $resource->{source} => "resources/$resource_subdir",
        $resource->{exclude}
    );
}

sub _tar_content_base64_encoded {
    my $self = shift;

    my $buffer;
    my $io = IO::String->new($buffer);
    $self->tar->write($io);

    if ($self->debug) {
        $self->tar->write('/tmp/provision.tar');
    }

    return encode_base64($buffer);
}

sub remote_execute {
    my $self = shift;

    my $ssh_config = $self->config->{ssh} // {};
    my $identity_file = exists $ssh_config->{identity_file}
        ? "$ENV{HOME}/.ssh/$ssh_config->{identity_file}"
        : undef;
    my $user_prefix = exists $ssh_config->{user}
        ? "$ssh_config->{user}\@"
        : '';

    my @command_and_args = (
        '/usr/bin/ssh',
        (defined $identity_file
            ? ('-i' => $identity_file)
            : ()),
        '-C',
        ($ssh_config->{options} // ()),
        "$user_prefix$ssh_config->{hostname}",
        'perl -'
            . ($self->dryrun  ? ' -n' : '')
            . ($self->verbose ? ' -v' : '')
    );

    $self->log_debug('Executing:', @command_and_args);

    IPC::Run::run \@command_and_args,
                  \$self->script,
                  \&_print_stdout_in_green,
                  \&_print_stderr_in_red;
}

sub _print_stdout_in_green {
    print "\e[32m$_[0]\e[m";
}

sub _print_stderr_in_red {
    print "\e[31m$_[0]\e[m";
}

sub _boot_script {
    my $self = shift;

    return <<'EOF';
#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Cwd;
use Archive::Tar;
use File::Temp 'tempdir';

my $cwd      = getcwd;
my $temp_dir = tempdir(CLEANUP => 1);

chdir $temp_dir;
binmode DATA, ':via(Base64Decode)';
Archive::Tar->new(\*DATA)->extract;

chdir $cwd;
$ENV{PERL5LIB} = "$temp_dir/local/lib/perl5";
system "$temp_dir/provision.pl", @ARGV;

{
    package Base64Decode;
    use MIME::Base64;

    sub PUSHED {
        my ($class, $mode, $fh) = @_;

        my $buf = '';
        return bless \$buf, $class;
    }

    sub FILL {
        my ($obj, $fh) = @_;

        my $line = <$fh>;
        return defined $line
            ? decode_base64($line)
            : undef;
    }
}

# data contains base-64 encoded tar file, compression via ssh -C
__DATA__
EOF
}

1;
