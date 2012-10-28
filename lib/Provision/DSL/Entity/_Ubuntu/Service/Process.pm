package Provision::DSL::Entity::_Ubuntu::Service::Process;
use Moo;
use Path::Class;

extends 'Provision::DSL::Entity';
with    'Provision::DSL::Role::CommandExecution',
        'Provision::DSL::Role::ProcessControl';

sub _build_need_privilege { 1 }

sub inspect { $_[0]->is_running ? 'current' : 'missing' }

sub create { $_->_run_service('start') }
sub change { $_->_run_service('restart') }
sub remove { $_->_run_service('stop') }

sub _run_service {
    my ($self, $action) = @_;
    
    $self->run_command_as_superuser($self->name, $action);
}


1;
