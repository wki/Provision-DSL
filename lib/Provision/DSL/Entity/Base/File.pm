package Provision::DSL::Entity::Base::File;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::Path';

has path => (
    is     => 'lazy',
    coerce => to_File,
);
sub _build_path { $_[0]->name }

1;
