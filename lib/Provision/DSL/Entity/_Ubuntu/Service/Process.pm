package Provision::DSL::Entity::_Ubuntu::Service::Process;
use Moo;

extends 'Provision::DSL::Entity';
with    'Provision::DSL::Role::CommandExecution',
        'Provision::DSL::Role::ProcessControl';

sub _build_need_privilege { 1 }

sub inspect { $_[0]->pid && -e "/proc/${\$_[0]->pid}" ? 'current' : 'missing' }

sub create { $_->__service('start') }
sub change { $_->__service('restart') }
sub remove { $_->__service('stop') }

sub __service {
    my ($self, $action) = @_;
    
    $self->run_command_as_superuser($self->name, $action);
}

1;
