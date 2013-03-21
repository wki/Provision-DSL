package Provision::DSL::Script::DSL;
use Moo;

with 'Provision::DSL::Role::Provision';

sub BUILD {
    my $self = shift;
    
    $self->log_debug('BUILD', ref $self);
}

sub must_have_valid_syntax {
    my $self = shift;
    
    $self->log_debug(ref $self, 'must_have_valid_syntax');
    
    # TODO: fill me.
}

1;
