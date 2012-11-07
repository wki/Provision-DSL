package E;
use Moo;

with 'Provision::DSL::Role::User';

has name            => ( is => 'rw' );
has state           => ( is => 'rw', default => sub { '' } );
has path            => ( is => 'rw' );
has link_to         => ( is => 'rw' );
has need_privilege  => ( is => 'rw', default => sub { 0 } );
has started         => ( is => 'rw' );

sub add_to_state {
    my $self  = shift;
    my $state = shift;

    $self->state( join '/', ( $self->state || () ), ( $state || () ) );
}

1;
