package Provision::DSL::Role::PathPermission;
use Moo::Role;
use Provision::DSL::Types;

has permission => (
    is => 'lazy', 
    # coerce => to_Permission,
    # required => 1, 
);

around is_current => sub {
    my ($orig, $self) = @_;
    
    return ($self->path->stat->mode & 511) == (oct($self->permission) & 511) 
        && $self->$orig();
};

my $after_create_or_change = sub {
    my $self = shift;
    
    $self->log_dryrun("would chmod ${\oct($self->permission)}, ${\$self->path}")
        and return;
    
    chmod oct($self->permission), $self->path;
};

after create => $after_create_or_change;
after change => $after_create_or_change;

1;
