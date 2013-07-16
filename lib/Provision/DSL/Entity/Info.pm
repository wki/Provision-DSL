package Provision::DSL::Entity::Info;
use Moo;

extends 'Provision::DSL::Entity::Base::Message';

sub _build_default_state { 
    $_[0]->verbose > 1 ? 'outdated' : 'current'
}

1;
