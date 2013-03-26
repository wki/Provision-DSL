package Provision::DSL::Entity::Base::Dir;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::Path';

has path => (
    is     => 'lazy',
    coerce => to_Dir,
);

sub _build_path { $_[0]->name }

1;
