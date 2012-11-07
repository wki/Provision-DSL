package Provision::DSL::Inspector::FileExists;
use Moo;

extends 'Provision::DSL::Inspector';

sub _build_state { 
    (grep { !-f $_ || -l $_ } $_[0]->expected_values) ? 'missing' : 'current'
}

1;
