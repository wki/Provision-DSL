package Provision::DSL::Local::Daemon;
use Moo;
use POSIX ':sys_wait_h';

extends 'Provision::DSL::Base';
with 'Provision::DSL::Role::Local';

sub DEMOLISH { $_[0]->stop }

has pid => (
    is        => 'rw',
    predicate => 1,
    clearer   => 1,
);

sub start {
    my $self = shift;

    $self->stop if $self->is_running;

    $self->log_debug("starting '${\$self->name}' daemon");

    if (my $pid = fork) {
        # parent
        $self->pid($pid);

        # must let the daemon try to open the port
        sleep 1;

        die "could not start '${\$self->name}' -- port already bound?"
            if waitpid($pid, WNOHANG);
    } else {
        $self->start_deamon;
        
        exit 1;
    }
}

sub stop {
    my $self = shift;

    return if !$self->is_running;

    $self->log_debug("stopping '${\$self->name}' daemon");

    kill 9, $self->pid;
    sleep 1;
    
    $self->clear_pid;
}

sub is_running { $_[0]->has_pid }

1;
