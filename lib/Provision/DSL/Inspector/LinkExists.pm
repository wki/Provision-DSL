package Provision::DSL::Inspector::LinkExists;
use Moo;

extends 'Provision::DSL::Inspector::PathExists';

sub _build_state {
    -l $_[0]->value && readlink $_[0]->value eq $_[0]->entity->link_to
        ? 'current' 
        : 'missing' 
}

1;
