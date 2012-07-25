package Provision::DSL::Entity::TestingOnly;
use Moo;

extends 'Provision::DSL::Entity';

has foo => ( is => 'lazy' );
sub _build_foo { $_[0]->name }

has bar => ( is => 'ro', predicate => 1 );

has baz => ( is => 'ro', predicate => 1 );

1;
