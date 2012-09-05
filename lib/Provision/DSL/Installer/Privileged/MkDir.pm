package Provision::DSL::Installer::Privileged::MkDir;
use Moo;

extends 'Provision::DSL::Installer';

sub create {
    my $self = shift;
    
    $self->run_command_as_superuser(
        '/bin/mkdir',
        '-p', $self->entity->path
    );
}

sub remove {
    my $self = shift;

    $self->run_command_as_superuser(
        '/bin/rm',
        '-rf', $self->entity->path,
    );
}

1;
