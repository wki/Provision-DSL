package Provision::DSL::Entity::Perlbrew::Cpanm;
use Moo;
use Provision::DSL::Const;

extends 'Provision::DSL::Entity';
with    'Provision::DSL::Role::CommandExecution';

sub inspect { -f $_[0]->parent->cpanm ? 'current' : 'missing' }

sub create { goto \&change }
sub change {
    my $self = shift;
    
    $self->run_command_as_user(
        $self->parent->perl,
        $self->parent->perlbrew,
        'install-cpanm'
    );
}

1;
