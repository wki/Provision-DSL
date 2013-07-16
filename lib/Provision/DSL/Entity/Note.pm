package Provision::DSL::Entity::Note;
use Moo;

extends 'Provision::DSL::Entity::Base::Message';

sub _build_default_state { 
    $_[0]->verbose ? 'outdated' : 'current'
}

1;
