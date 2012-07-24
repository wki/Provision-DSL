package Provision::DSL::Role::User;
use Moo::Role;
use Provision::DSL::Types;

has user => (
    is => 'lazy',
    coerce => to_User,
    predicate => 1,
);

1;
