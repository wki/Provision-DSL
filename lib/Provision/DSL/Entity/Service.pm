package Provision::DSL::Entity::Service;
use Moo;

extends 'Provision::DSL::Entity::File';
with    'Provision::DSL::Role::CommandExecution',
        'Provision::DSL::Role::ProcessControl';

has process => (
    is => 'lazy', # builder must be defined in derieved class
);

1;
