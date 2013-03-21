package Provision::DSL::Script::Timer;
use Moo;
use Time::HiRes qw(gettimeofday tv_interval);

with 'Provision::DSL::Role::Provision';

has start_time => ( is => 'rw' );

sub BUILD {
    my $self = shift;
    
    $self->log_debug('BUILD', ref $self);
    $self->start;
}

sub start {
    my $self = shift;
    
    $self->start_time( [gettimeofday] )
}

sub elapsed {
    my $self = shift;
    
    return tv_interval($self->start_time, [gettimeofday]);
}

1;
