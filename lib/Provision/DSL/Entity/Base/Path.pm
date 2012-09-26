package Provision::DSL::Entity::Base::Path;
use Moo;
use Try::Tiny;
use Provision::DSL::Types;

# Abstract base class for Dir/File/Link / Rsync?

extends 'Provision::DSL::Entity';
with    'Provision::DSL::Role::CommandExecution';

sub need_privilege {
    my $self = shift;

    return 1 if $self->has_user  && $self->uid != $<;
    return 1 if $self->has_group && $self->gid != $(;

    if (-e $self->path) {
        return __is_not_mine($self->path);
    }

    my $ancestor = $self->path->parent;
    while (!-d $ancestor && scalar $ancestor->dir_list > 1) {
        $ancestor = $ancestor->parent;
    }

    return __is_not_mine($ancestor);
}

sub __is_not_mine {
    my $path = shift;

    my $stat = $path->stat;
    return $stat->uid != $< || $stat->gid != $(;
}

sub prepare_for_creation {
    my $self = shift;

    if (-e $self->path) {
        $self->remove;
    }

    if (!-d $self->path->parent) {
        $self->run_command_maybe_privileged(
            '/bin/mkdir',
            '-p', $self->path->parent,
        );
        
        ### TODO: change ownership ???
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
