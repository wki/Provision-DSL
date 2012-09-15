package Provision::DSL::Inspector::FileExists;
use Moo;

extends 'Provision::DSL::Inspector::PathExists';

sub _build_state { -f $_[0]->value && !-l $_[0]->value ? 'current' : 'missing' }

1;
