package Provision::DSL::Role::ProcessControl;
use Moo::Role;
use Provision::DSL::Types;
use Provision::DSL::Util 'os';

with "Provision::DSL::Role::ProcessControl::${\os}";

has pid_file => (
    is => 'ro',
    coerce => to_File,
    predicate => 1,
);

# a pid of 0 indicates a non-running process, undef no pid-file
sub pid {
    my $self = shift;
    
    return $self->has_pid_file && -f $self->pid_file
        ? $self->read_content_of_file($self->pid_file) + 0
        : undef;
}

1;
