package Provision::DSL::Entity::Service;
use Moo;

extends 'Provision::DSL::Entity::File';
with    'Provision::DSL::Role::CommandExecution',
        'Provision::DSL::Role::ProcessControl';

1;
