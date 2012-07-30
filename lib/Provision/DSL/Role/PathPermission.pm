package Provision::DSL::Role::PathPermission;
use Moo::Role;
use Provision::DSL::Types;

has permission => (
    is => 'lazy', 
    coerce => to_Permission,
);

before state => sub {
    my $self = shift;
    
    return if !-d $self->path;
    
    $self->add_state('outdated')
        if ($self->path->stat->mode & 511) != ($self->permission & 511)
};

after ['create', 'change'] => sub {
    my $self = shift;
    
    chmod $self->permission, $self->path;
};

1;
