package Provision::DSL::Installer::MkDir;
use Moo;

extends 'Provision::DSL::Installer::PathBase';

sub create {
    my $self = shift;
    
    $self->prepare_for_creation;
    
    $self->run_command_maybe_privileged(
        '/bin/mkdir',
        '-p', $self->entity->path,
    );
}

1;
