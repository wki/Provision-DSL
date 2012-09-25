package Provision::DSL::Installer::PathBase;
use Moo;

extends 'Provision::DSL::Installer';
with    'Provision::DSL::Role::CommandExecution';

# before 'create' does not work in parent class
sub prepare_for_creation {
    my $self = shift;

    $self->remove if -e $self->path;

    if (!-d $self->entity->path->parent) {
        $self->run_command_maybe_privileged(
            '/bin/mkdir',
            '-p', $self->path->parent,
        );
    }
};

sub remove {
    my $self = shift;

    $self->run_command_maybe_privileged(
        '/bin/rm',
        '-rf',
        $self->path,
    );
}

1;
