package Provision::DSL::Role::PathPermission;
use Moo::Role;
use Provision::DSL::Types;

has permission => (
    is => 'lazy', 
    # coerce => to_Permission,
    # required => 1, 
);

around state => sub {
    my ($orig, $self) = @_;
    
    my $state = 
        !-e $self->path 
            ? 'missing'
        : ($self->path->stat->mode & 511) == (oct($self->permission) & 511)
            ? 'current'
            : 'outdated';
    
    return $state eq $self->$orig
        ? $state
        : 'outdated';
};

after ['create', 'change'] => sub {
    my $self = shift;
    
    chmod oct($self->permission), $self->path;
};

1;
