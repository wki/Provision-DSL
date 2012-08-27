package Provision::DSL::Inspector::Always;
use Moo;

extends 'Provision::DSL::Inspector';

sub _build_state { 'outdated' }

1;
