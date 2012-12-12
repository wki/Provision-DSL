package Provision::DSL::Entity::_Ubuntu::Service::Process;
use Moo;
use Path::Class;

extends 'Provision::DSL::Entity';
with    'Provision::DSL::Role::CommandExecution',
        'Provision::DSL::Role::ProcessControl';

sub _build_need_privilege { 1 }

sub inspect {
    # not very cool to introspect parent's secret state, but neccesary.
    # Reason: _state contains the "running state" during state calculation
    #         its content is taken to force restart the service
    $_[0]->is_running 
        ? $_[0]->parent->_state
        : 'missing'
}

sub create { $_->_run_service('start') }
sub change { $_->_run_service('restart') }
sub remove { $_->_run_service('stop') }

sub _run_service {
    my ($self, $action) = @_;
    
    $self->run_command_as_superuser($self->name, $action);
}


1;
