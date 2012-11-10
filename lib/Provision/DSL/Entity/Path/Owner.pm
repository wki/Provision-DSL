package Provision::DSL::Entity::Path::Owner;
use Moo;
use Carp;
use Provision::DSL::Const;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::Path';

has path => (
    is => 'ro',
    required => 1,
);

sub inspect { 
    my $self = shift;

    return 'missing'  if !defined $self->path || !-e $self->path;
    return 'outdated' if $self->has_user && $self->path->stat->uid != $self->uid;
    return 'outdated' if $self->has_group && $self->path->stat->gid != $self->gid;
    return 'current'
}

sub create { goto \&change }
sub change {
    my $self = shift;
    
    if ($self->has_user) {
        $self->run_command_as_superuser(
            CHOWN,
            '-R',
            $self->user,
            $self->path,
        );
    }
    if ($self->has_group) {
        $self->run_command_as_superuser(
            CHGRP,
            '-R',
            $self->group,
            $self->path,
        );
    }
}

1;
