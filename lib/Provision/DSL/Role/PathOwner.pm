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

around is_ok => sub {
    my ($orig, $self) = @_;
    
    return -e $self->path 
        && ($self->path->stat->uid == $self->uid)
        && ($self->path->stat->gid == $self->gid)
        && $self->$orig();
};

after create => sub {
    my $self = shift;
    
    chown $self->uid, $self->gid, $self->path;
};

1;
