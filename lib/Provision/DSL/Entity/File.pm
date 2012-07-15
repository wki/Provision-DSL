package Provision::DSL::Entity::File;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';

sub path;       # must forward-declare
sub content;    # must forward-declare

# with 'Provision::DSL::Role::PathPermission',
#      'Provision::DSL::Role::PathOwner';

sub _build_permission { '0644' }

has path => (
    is => 'lazy',
    coerce => to_File,
);

sub _build_path { $_[0]->name }

has content => (
    is => 'ro',
    isa => Str,
    coerce => to_Str,
    required => 1,
);

sub is_present { -f $_[0]->path }

sub is_current {
    my $self = shift;
    
    return $self->is_present
        && scalar $self->path->slurp eq $self->content;
}

after ['create', 'change'] => sub {
    my $self = shift;
    
    my $fh = $self->path->openw;
    print $fh $self->content;
    $fh->close;
};

after remove => sub { $_[0]->path->remove };

1;
