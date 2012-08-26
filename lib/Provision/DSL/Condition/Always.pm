package Provision::DSL::Condition::Always;
use Moo;

extends 'Provision::DSL::Condition';

sub state { 'outdated' }

1;
