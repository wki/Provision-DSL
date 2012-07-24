package Provision::DSL::Source;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Base';

has content => (
    is => 'lazy',
    isa => Str,
);

# builder must be created in child class if content wanted

1;
