package Provision::DSL::Inspector::LinkExists;
use Moo;

extends 'Provision::DSL::Inspector';

sub _build_state { 
    (grep { !-l $_ } $_[0]->expected_values) ? 'missing' : 'current'
}

1;
