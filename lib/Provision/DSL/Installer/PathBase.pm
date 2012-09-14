package Provision::DSL::Installer::PathBase;
use Moo;

extends 'Provision::DSL::Installer';

before create => sub {
    my $self = shift;

    if (-e $self->entity->path) {
        $self->remove;
    }

    if (!-d $self->entity->path->parent) {
        $self->run_command_maybe_privileged(
            '/bin/mkdir',
            '-p', $self->entity->path->parent,
        );
    }
};

sub remove {
    my $self = shift;

    $self->run_command_maybe_privileged(
        '/bin/rm',
        '-rf',
        $self->entity->path,
    );
}

1;
