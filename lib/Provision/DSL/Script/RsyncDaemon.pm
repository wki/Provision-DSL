package Provision::DSL::Script::RsyncDaemon;
use Moo;

with 'Provision::DSL::Role::Provision';

sub BUILD {
    my $self = shift;
    
    $self->log_debug('BUILD', ref $self);
}

sub start {
    my $self = shift;
    
    $self->log_debug(ref $self, 'start');
    
    # TODO: fill me.
}

sub stop {
    my $self = shift;
    
    $self->log_debug(ref $self, 'stop');
    
    # TODO: fill me.
}

1;
