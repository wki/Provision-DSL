package Provision::DSL::Role::PathOwner;
use Moo::Role;
use Provision::DSL::Types;

with 'Provision::DSL::Role::User',
     'Provision::DSL::Role::Group';

before calculate_state => sub {
    my $self = shift;

    return if !-d $self->path;

    $self->add_to_state('outdated')
        if    ($self->has_user
                && $self->path->stat->uid != $self->user->uid)
           || ($self->has_group
                && $self->path->stat->gid != $self->group->gid);
};

after ['create', 'change'] => sub {
    my $self = shift;

    chown $self->user->uid, $self->group->gid, $self->path;
};

1;
