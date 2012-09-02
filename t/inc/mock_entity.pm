package E;
use Moo;

with 'Provision::DSL::Role::User';
with 'Provision::DSL::Role::Group';

has state => (
    is      => 'rw',
    default => sub { '' },
);

has path => ( is => 'rw' );

sub add_to_state {
    my $self  = shift;
    my $state = shift;

    $self->state( join '/', ( $self->state || () ), ( $state || () ) );
}

1;
