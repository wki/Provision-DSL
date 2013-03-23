package Provision::DSL::Local::Proxy;
use Moo;
use PerlIO::via::ANSIColor;
use Net::OpenSSH;
use IO::Multiplex;
use Path::Class ();

with 'Provision::DSL::Role::Local';

has host => (
    is       => 'rw',
    required => 1,
);

has options => (
    is      => 'ro',
    default => sub { +{} },
);

has stderr_color => (
    is        => 'ro',
    default   => sub { 'red' },
    predicate => 1,
);

has stdout_color => (
    is        => 'ro',
    predicate => 1,
);

has ssh => (
    is => 'lazy',
);

sub _build_ssh {
    my $self = shift;

    PerlIO::via::ANSIColor->paint(*STDOUT, $self->stdout_color)
        if $self->has_stdout_color;

    PerlIO::via::ANSIColor->paint(*STDERR, $self->stderr_color)
        if $self->has_stderr_color;

    return Net::OpenSSH->new($self->host, %{$self->options});
}

sub run_command {
    my $self = shift;

    $self->log_debug('Remote-Executing command: ', @_);

    my ($in, $out, $err, $pid) =
        $self->ssh->open3(map { "$_" } @_);

    my $mux = IO::Multiplex->new;
    $mux->add($out);
    $mux->set_callback_object(__PACKAGE__ . '::STDOUT', $out);

    $mux->add($err);
    $mux->set_callback_object(__PACKAGE__ . '::STDERR', $err);

    $mux->loop;
}

sub pull_cache {
    my $self = shift;

    $self->log(' - Remote: pulling cache');

    my $remote      = $self->config->remote;
    my $environment = $remote->{environment};

    my $rsync       = $environment->{PROVISION_RSYNC};
    my $port        = $environment->{PROVISION_RSYNC_PORT};
    my $dir_name    = $self->app->cache->dir->basename;
    my $archname    = $self->app->archname;

    $self->run_command(
        $rsync,
        '-cr',
        '--perms',
        '--delete',
        '--exclude', '"/lib/**.pod"',
        '--exclude', "/lib/perl5/$archname",
        '--exclude', '/rsyncd.conf',
        '--exclude', '/log',
        "rsync://127.0.0.1:$port/local" => "$dir_name/"
    );
}

sub run_dsl {
    my $self = shift;

    $self->log(' - Remote: running dsl');

    my $provision_start_script =
        Path::Class::File->new(
            $self->app->cache->dir->basename,
            $self->app->cache->provision_start_script->basename
        );

    $self->run_command(
        $provision_start_script,
        ($self->dryrun  ? '-n' : ()),
        ($self->verbose ? '-v' : ()),
        '-l', 'log',
        '-U', ((getpwuid($<))[6]),
        @_
    );
}

sub push_logs {
    my $self = shift;

    $self->log(' - Remote: pushing logs');

    my $remote      = $self->config->remote;
    my $environment = $remote->{environment};

    my $rsync       = $environment->{PROVISION_RSYNC};
    my $port        = $environment->{PROVISION_RSYNC_PORT};
    my $dir_name    = $self->app->cache->dir->basename;
    my $archname    = $self->app->archname;

    $self->run_command(
        $rsync,
        '-cr',
        '--delete',
        "$dir_name/log/" => "rsync://127.0.0.1:$port/log/"
    );
}


# -----------------------------------------------[ Mux stuff

package Provision::DSL::Local::Proxy::STDOUT;
use Term::ANSIColor;

sub mux_input {
    my ($package, $mux, $fh, $input) = @_;

    # uni-colored: # print $$input;
    foreach my $line (split qr/\n/xms, $$input) {
        if ($line =~ m{\A (.*\s+) (\w+\s-\sOK) \z}xms) {
            printf colored ['green'], substr($1 . '.' x 80, 0, 77 - length $2) . ' ';
            print colored ['reverse green'], "$2\n";
        } elsif ($line =~ m{\A (.*\s+) (\w+\s(?:-\swould\s\w+ | =>\s+\w+)) \z}xms) {
            printf colored ['magenta'], substr($1 . '.' x 80, 0, 77 - length $2) . ' ';
            print colored ['reverse magenta'], "$2\n";
        } else {
            print $line;
        }
    }
}

package Provision::DSL::Local::Proxy::STDERR;

sub mux_input {
    my ($package, $mux, $fh, $input) = @_;

    print STDERR $$input;
}

1;
