package Provision::DSL::Script::Remote;
use Moo;
use PerlIO::via::ANSIColor;
use Net::OpenSSH;
use IO::Multiplex;

extends 'Provision::DSL::Base';

has host => (
    is => 'lazy',
);

sub _build_host { $_[0]->name }

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
