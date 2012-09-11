package Provision::DSL::Role::PathOwner;
use Moo::Role;
use Provision::DSL::Types;

before calculate_state => sub {
    my $self = shift;

    return if !-d $self->path;

    $self->add_to_state('outdated') if $self->_need_change;
};

sub _need_change {
    my $self = shift;
    
    return ($self->has_user
                && $self->path->stat->uid != $self->user->uid)
        || ($self->has_group
                && $self->path->stat->gid != $self->group->gid);
}

after ['create', 'change'] => sub {
    my $self = shift;

    return if !$self->_need_change;

    chown
        $self->has_user 
            ? $self->user->uid
            : $<, 
        $self->has_group
            ? $self->group->gid
            : $(, 
        $self->path;
};

1;
