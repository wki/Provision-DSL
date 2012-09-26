package Provision::DSL::Entity::Service;
use Moo;

extends 'Provision::DSL::Entity::File';

has pid_file => (
    is => 'ro',
    coerce => to_File,
    predicate => 1,
);

sub pid {
    my $self = shift;
    
    my $pid;
    if ($self->has_pid_file) {
        $pid = 0 + scalar $self->pid_file->slurp;
    }
    
    return $pid;
}

# TODO: children
#   - Service_Process, inspector übernehmen


1;
