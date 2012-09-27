package Provision::DSL::Entity::Perlbrew::Cpanm;
use Moo;

extends 'Provision::DSL::Entity';
with    'Provision::DSL::Role::CommandExecution';

sub inspect { -f $_[0]->parent->cpanm ? 'current' : 'missing' }

sub create { goto \&change }
sub change {
    my $self = shift;
    
    $self->run_command_as_user(
        '/usr/bin/perl',
        $self->parent->perlbrew,
        'install-cpanm'
    );
}

1;
