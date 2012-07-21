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

around state => sub {
    my ($orig, $self) = @_;
    
    my $state = !-e $self->path
        ? 'missing'
    : ($self->path->stat->uid == $self->uid)
       && ($self->path->stat->gid == $self->gid)
        ? 'current'
        : 'outdated';
    
    return $state eq $self->$orig()
        ? $state
        : 'outdated';
};

after ['create', 'change'] => sub {
    my $self = shift;
    
    chown $self->uid, $self->gid, $self->path;
};

1;
