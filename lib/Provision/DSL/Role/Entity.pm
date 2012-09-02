package Provision::DSL::Role::Entity;
use Moo::Role;

has entity => (
    is => 'ro',
    required => 1,
    weak_ref => 1,
);

1;
