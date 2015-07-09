package Provision::DSL::Entity::Error;
use Moo;
use Carp;

extends 'Provision::DSL::Entity';

has args => (
    is => 'ro',
);

sub _build_default_state { 'missing' }

sub install {
    my $self = shift;
    
    my @log = ($self, 'impossible');
    
    $self->log_dryrun(@log, "- could work") and return;
    $self->log(@log, "=> FAIL");
    
    croak "Cannot continue, faild to install '${\$self->name}'";
}

1;
