package Provision::DSL::Role::PathPermission;
use Moo::Role;
use Provision::DSL::Types;

has permission => (
    is     => 'lazy', 
    coerce => to_Permission,
);

1;
