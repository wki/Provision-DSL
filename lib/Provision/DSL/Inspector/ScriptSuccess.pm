package Provision::DSL::Inspector::ScriptSuccess;
use Moo;

extends 'Provision::DSL::Inspector';
with 'Provision::DSL::Role::CommandExecution';

sub state {
    $_[0]->command_succeeds($_[0]->values)
        ? 'current'
        : 'outdated';
}

1;
