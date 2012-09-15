package E;
use Moo;

with 'Provision::DSL::Role::User';

has name            => ( is => 'rw' );
has state           => ( is => 'rw', default => sub { '' } );
has path            => ( is => 'rw' );
has need_privilege  => ( is => 'rw', default => sub { 0 } );

sub add_to_state {
    my $self  = shift;
    my $state = shift;

    $self->state( join '/', ( $self->state || () ), ( $state || () ) );
}

1;
