package Provision::DSL::Entity::File;
use Moo;
# use Carp;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::File';

sub BUILD {
    my $self = shift;

    $self->add_children(
        $self->__content,
        $self->__patch,
        $self->__permission,
        $self->__owner,
    );
}

sub _build_permission { '0644' }

has content => (
    is        => 'ro',
    isa       => Str,
    coerce    => to_Content,
    predicate => 1,
);

has patches => (
    is        => 'ro',
    predicate => 1,
);
 
sub inspect { -f $_[0]->path ? 'current' : 'missing' }

sub create {
    my $self = shift;
    
    $self->prepare_for_creation;
    
    $self->run_command_maybe_privileged(
        '/usr/bin/touch',
        $self->path,
    );
    
}

sub __content {
    my $self = shift;
    
    return if !$self->has_content;
    
    return $self->create_entity(
        File_Content => {
            parent  => $self,
            name    => $self->name,
            path    => $self->path,
            content => $self->content,
        }
    );
}

sub __patch {
    my $self = shift;
    
    return if !$self->has_patches;

    return $self->create_entity(
        File_Patch => {
            parent  => $self,
            name    => $self->name,
            path    => $self->path,
            patches => $self->patches,
        }
    );
}        

1;
