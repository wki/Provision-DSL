package Provision::DSL::Inspector::ScriptSuccess;
use Moo;

extends 'Provision::DSL::Inspector';
with 'Provision::DSL::Role::CommandExecution';

sub _build_attribute { 'path' }

sub _build_state {
    $_[0]->command_succeeds($_[0]->expected_values)
        ? 'current'
        : 'outdated';
}

1;
