package Provision::DSL::Inspector::DirExists;
use Moo;

extends 'Provision::DSL::Inspector::PathExists';

sub state { -d $_[0]->value ? 'current' : 'missing' }

1;
