package Provision::DSL::Condition::ScriptSuccess;
use Moo;

extends 'Provision::DSL::Condition';
with 'Provision::DSL::Role::CommandExecution';

sub state {
    my $self = shift;
    
    my ($script, @args) = ref $self->value eq 'ARRAY' 
        ? @{$self->value}
        : $self->value;
    
    return $self->command_succeeds($script, @args)
        ? 'current'
        : 'outdated';
}

1;
