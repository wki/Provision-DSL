package Provision::DSL::Inspector::_Ubuntu::Service;
use Moo;

extends 'Provision::DSL::Inspector';
with 'Provision::DSL::Role::CommandExecution';

sub _build_state {
    my $self = shift;
    
    my $service_script = "/etc/init.d/${\$_[0]->value}";
    
    my $state = 'missing';
    
    if (-f $service_script) {
        my $result = $self->run_command($service_script, 'status');
        $state = $result =~ m{running}xms
            ? 'current'
            : 'outdated';
    }
    
    return $state;
}

sub _build_need_privilege { 1 }

1;
