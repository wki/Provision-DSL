package Provision::DSL::Local::Timer;
use Moo;
use Time::HiRes qw(gettimeofday tv_interval);

with 'Provision::DSL::Role::Local';

has start_time => (
    is      => 'rw', 
    default => sub { [gettimeofday] },
);

sub start {
    my $self = shift;
    
    $self->start_time( [gettimeofday] )
}

sub elapsed {
    my $self = shift;
    
    return tv_interval($self->start_time, [gettimeofday]);
}

1;
