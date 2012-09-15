package Provision::DSL::Installer::Self;
use Moo;

extends 'Provision::DSL::Installer';

sub create { $_[0]->entity->self_create }
sub change { $_[0]->entity->self_change }
sub remove { $_[0]->entity->self_remove }

1;
