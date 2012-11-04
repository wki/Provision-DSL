package Provision::DSL::Inspector::ProcessAge;
use Moo;
use Path::Class;

extends 'Provision::DSL::Inspector';

sub _build_attribute { 'process' }

sub _build_state {
    my $self = shift;

    my $destination_process = $self->value;

    return 'missing' if !-e $destination_process;

    # ... TODO: Age ermitteln

    return 'current';
}

1;
