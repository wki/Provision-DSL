package Provision::DSL::Inspector::Never;
use Moo;

extends 'Provision::DSL::Inspector';

sub _build_state { 'current' }

1;
