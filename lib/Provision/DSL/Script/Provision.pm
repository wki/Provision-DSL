package Provision::DSL::Script::Provision;
use Moo;
use feature ':5.10';
use Archive::Tar;
use Archive::Tar::Constant;
use Path::Class;
use IO::String;
use MIME::Base64;
use Cwd;
use IPC::Run3;
use Config;
use Try::Tiny;
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
    is       => 'ro',
    required => 1,
    coerce   => sub { do $_[0] },
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

has temp_lib_dir => (
    is     => 'lazy',
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

    file('/tmp/provision.pl')->spew($self->script)
        if ($self->debug);

    my $result = $self->remote_provision;

    $self->log('Finished Provisioning');
    exit $? >> 8; ### FIXME: get remote provision status somehow.
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
        next if -f $self->temp_lib_dir->file($lib_filename);

        $self->run_command(
            'cpanm',
            -L => $self->temp_lib_dir,
            -n => $lib
        );
    }

    $self->_pack_file_or_dir(
        $self->temp_lib_dir,
        '.' => "local",
        [ $Config{archname}, '*.pod' ], # exclude binary-dir and documentation
    );
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
        'Provision' => 'local/lib/perl5/Provision',

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
            $self->tar->add_data(
                $dest_path,
                '',
                { type => DIR, mode => 0755, %$options },
            );
        } else {
            $self->log_debug('adding FILE:', $relative_file_name, $dest_path);
            $self->__pack_file($child => $dest_path, $options);
        }
        return $cont->();
    });

}

sub __pack_file {
    my ($self, $file, $dest_file, $options) = @_;

    $self->tar->add_data(
        $dest_file,
        scalar $file->slurp,
        { type => FILE, mode => 0644, %$options },
    );
}

sub pack_provision_script {
    my $self = shift;

    my $provision_file_name = $self->config->{provision_file} // 'provision.pl';
    my $provision_dir = $self->root_dir->file($provision_file_name)->dir;
    my $provision_script = scalar $self->root_dir->file($provision_file_name)->slurp;

    $provision_script =~ s{^ \s*
                           include\s+               # 'include' keyword
                           (\w+)                    # $1: file to include
                           (?:\s* ,? \s* (.+?) )?   # $2: optional args
                           \s* ; \s*
                           [#] .*
                           $
                           }{$self->_include($provision_dir->file("$1.pl"), $2)}exmsg;

    $self->log(" - packing provision script '$provision_file_name'");

    warn "SCRIPT = $provision_script"; die 'stop for testing' ;

    $self->tar->add_data(
        'provision.pl',
        $provision_script,
        { type => FILE, mode => 0755 },
    );
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

sub remote_provision {
    my $self = shift;

    my $ssh_config = $self->config->{ssh} // {};
    my $identity_file = exists $ssh_config->{identity_file}
        ? "$ENV{HOME}/.ssh/$ssh_config->{identity_file}"
        : undef;
    my $user_prefix = exists $ssh_config->{user}
        ? "$ssh_config->{user}\@"
        : '';

    my @command_and_args = (
        #
        # establish an ssh connection with compression
        #
        '/usr/bin/ssh',
        (defined $identity_file
            ? ('-i' => $identity_file)
            : ()),
        '-C',   # compress data
        (map { ref $_ eq 'ARRAY' ? @$_ : $_ } ($ssh_config->{options} // ())),
        "$user_prefix$ssh_config->{hostname}",

        #
        # provision perl running script from stdin (-) with options
        # try to find the perl binary with the highest version number
        # otherwise OS-X Tiger systems would only use 5.8.9 which fails here.
        #
        'env `ls -1 -r /usr/bin/perl5.1* /usr/bin/perl | head -1` -'
            . ($self->dryrun  ? ' -n' : '')
            . ($self->verbose ? ' -v' : '')
    );

    $self->log(' - running provision script on', $ssh_config->{hostname});
    $self->log_debug('Executing:', @command_and_args);

    # redirecting stdout/stderr will buffer.
    # FIXME: find out how to avoid...
    run3 \@command_and_args,
         \$self->script,               # STDIN
         #\&_print_stdout_in_green,     # STDOUT
         #\&_print_stderr_in_red;       # STDERR
         ;
}

sub _print_stdout_in_green {
    print "\e[32m$_[0]\e[m";
}

sub _print_stderr_in_red {
    print "\e[31m$_[0]\e[m";
}

sub _boot_script {
    #
    # for "booting" on a remote maching, at least Perl 5.10 is required.
    # Archive::Tar is in CORE since this version of Perl, not before.
    #
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
