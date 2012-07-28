package Provision::DSL::Role::PathOwner;
use Moo::Role;
use Provision::DSL::Types;

has uid => (
    is => 'lazy', 
    coerce => to_Uid,
);

has gid => (
    is => 'lazy', 
    coerce => to_Gid,
);

before state => sub {
    my $self = shift;
    
    return if !-d $self->path;
    
    $self->add_state('outdated')
        if ($self->path->stat->uid != $self->uid)
           || ($self->path->stat->gid != $self->gid)
};

after ['create', 'change'] => sub {
    my $self = shift;
    
    chown $self->uid, $self->gid, $self->path;
};

1;
