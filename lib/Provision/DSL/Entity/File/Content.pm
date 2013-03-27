package Provision::DSL::Entity::File::Content;
use Moo;
use Carp;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::File';
with 'Provision::DSL::Role::Content';

sub inspect { 
    my $self = shift;

    die "$self: content is required" if !$self->has_content;

    return !defined $self->current_content
        ? 'missing'
    : $self->current_content ne $self->content
        ? 'outdated'
        : 'current';
}

sub create { goto \&change }
sub change {
    my $self = shift;
    
    $self->write_content($self->content);
}

1;
