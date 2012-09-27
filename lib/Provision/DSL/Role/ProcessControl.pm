package Provision::DSL::Role::ProcessControl;
use Moo::Role;
use Provision::DSL::Types;

has pid_file => (
    is => 'ro',
    coerce => to_File,
    predicate => 1,
);

# a pid of 0 indicates a non-running process, undef no pid-file
sub pid {
    my $self = shift;
    
    return $self->has_pid_file && -f $self->pid_file
        ? $self->run_command_maybe_privileged('/bin/cat', $self->pid_file) + 0
        : undef;
}

1;
