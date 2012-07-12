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

around is_current => sub {
    my ($orig, $self) = @_;
    
    return -e $self->path 
        && ($self->path->stat->uid == $self->uid)
        && ($self->path->stat->gid == $self->gid)
        && $self->$orig();
};

my $after_create_or_change = sub {
    my $self = shift;
    
    $self->log_dryrun("would chown ${\$self->uid}:${\$self->gid}, ${\$self->path}")
        and return;
    
    chown $self->uid, $self->gid, $self->path;
};

after create => $after_create_or_change;
after change => $after_create_or_change;

1;
