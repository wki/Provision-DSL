package Provision::DSL::Installer::Link;
use Moo;

extends 'Provision::DSL::Installer::PathBase';

sub create {
    my $self = shift;
    
    $self->prepare_for_creation;
    
    $self->run_command_maybe_privileged(
        '/bin/ln',
        '-s', $self->entity->link_to, $self->entity->path
    );
}

1;
