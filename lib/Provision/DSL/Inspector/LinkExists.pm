package Provision::DSL::Inspector::LinkExists;
use Moo;

extends 'Provision::DSL::Inspector::PathExists';

sub state { -l $_[0]->value ? 'current' : 'missing' }

1;
