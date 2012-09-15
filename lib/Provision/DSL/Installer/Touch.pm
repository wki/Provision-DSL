package Provision::DSL::Installer::Touch;
use Moo;

extends 'Provision::DSL::Installer::PathBase';

sub create {
    my $self = shift;
    
    $self->prepare_for_creation;
    
    $self->run_command_maybe_privileged(
        '/usr/bin/touch',
        $self->entity->path,
    );
}

1;
