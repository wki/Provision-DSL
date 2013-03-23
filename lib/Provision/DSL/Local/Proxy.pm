package Provision::DSL::Local::Proxy;
use Moo;
use PerlIO::via::ANSIColor;
use Net::OpenSSH;
use IO::Multiplex;

with 'Provision::DSL::Role::Local';

has host => (
    is => 'rw',
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

    my ($in, $out, $err, $pid) = $self->ssh->open3(@_);

    my $mux = IO::Multiplex->new;
    $mux->add($out);
    $mux->set_callback_object(__PACKAGE__ . '::STDOUT', $out);

    $mux->add($err);
    $mux->set_callback_object(__PACKAGE__ . '::STDERR', $err);

    # $mux->set_callback_object(__PACKAGE__);
    $mux->loop;
}

### SET ENV:
###
### qq{export dir="\$HOME/$dir_name";},
### qq{export PERL5LIB="\$dir/lib/perl5";},
### 
### (
###     map { qq{export $_="$remote->{environment}->{$_}";} }
###     keys %{$remote->{environment}}
### ),


sub pull_cache {
    # '$PROVISION_RSYNC',
    #     '-cr',
    #     '--perms',
    #     '--delete',
    #     '--exclude', '"/lib/**.pod"',
    #     '--exclude', "/lib/perl5/${\$self->archname}",
    #     '--exclude', '/rsyncd.conf',
    #     '--exclude', '/log',
    #     'rsync://127.0.0.1:$PROVISION_RSYNC_PORT/local' => '$dir/'
}

sub run_dsl {
    # '$PROVISION_PERL', '$dir/provision.pl',
    #     ($self->dryrun  ? ' -n' : ()),
    #     ($self->verbose ? ' -v' : ()),
    #     '-l', '$dir/log',
    #     '-U', '"' . ((getpwuid($<))[6]) . '"'
    #     # TODO: add more options
}

sub push_logs {
    # '$PROVISION_RSYNC',
    #     '-cr',
    #     '--delete',
    #     '$dir/log/' => 'rsync://127.0.0.1:$PROVISION_RSYNC_PORT/log/;'
}


# -----------------------------------------------[ Mux stuff

package Provision::DSL::Script::Remote::STDOUT;

sub mux_input {
    my ($package, $mux, $fh, $input) = @_;

    print $$input;
}

package Provision::DSL::Script::Remote::STDERR;

sub mux_input {
    my ($package, $mux, $fh, $input) = @_;

    print STDERR $$input;
}

1;
