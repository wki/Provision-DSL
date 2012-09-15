package Provision::DSL::Inspector::Self;
use Moo;

extends 'Provision::DSL::Inspector';

sub _build_state          { $_[0]->entity->self_calculate_state }
sub _build_need_privilege { $_[0]->entity->self_calculate_need_privilege }

1;
