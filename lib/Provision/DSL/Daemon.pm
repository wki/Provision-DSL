package Provision::DSL::Daemon;
use Moo;
use POSIX ':sys_wait_h';

extends 'Provision::DSL::Base';
with 'Provision::DSL::Role::CommandAndArgs';

has pid => (
    is        => 'rw',
    predicate => 'has_pid',
    clearer   => 'clear_pid',
);

sub start {
    my $self = shift;
    
    $self->stop if $self->is_running;
    
    if (my $pid = fork) {
        # parent
        $self->pid($pid);
        # warn 'starting daemon:', $self->name, ' pid:', $pid, ' mypid:', $$;
        sleep 1;
        
        die "could not start '${\$self->name}' -- port already bound?"
            if waitpid($pid, WNOHANG);
    } else {
        # child
        exec $self->command, @{$self->args};
        
        # never reached, but we are careful...
        exit 1;
    }
}

sub stop {
    my $self = shift;
    
    return if !$self->is_running;
    
    # warn 'stopping daemon:', $self->name;
    
    kill 9, $self->pid;
    sleep 1;
    
    $self->clear_pid;
}

sub is_running { $_[0]->has_pid }

sub DEMOLISH { $_[0]->stop }

1;
