package Provision::DSL::Inspector::FileExists;
use Moo;

extends 'Provision::DSL::PathExists';

sub state { -f $_[0]->value ? 'current' : 'missing' }

1;
