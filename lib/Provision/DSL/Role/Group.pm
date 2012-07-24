package Provision::DSL::Role::Group;
use Moo::Role;
use Provision::DSL::Types;

has group => (
    is => 'lazy',
    coerce => to_Group,
    predicate => 1,
);

1;
