package Provision::DSL::Inspector;
use Moo;
use Carp;
use Provision::DSL::Types;

with 'Provision::DSL::Role::Entity';

has attribute => (
    is        => 'lazy',
    predicate => 1,
);

# must be present in implementation if attribute is needed
# sub _build_attribute { }

has expected_value => (
    is        => 'ro',
    predicate => 1,
);

# return values as list
sub expected_values {
    my $self = shift;

    my $value = $self->expected_value;

    return ref $value eq 'ARRAY'
      ? @$value
      : $value;
}

has state => (
    is      => 'lazy',
    isa     => State,
    clearer => 1,
);

sub _build_state { croak '_build_state must be defined in implementation' }

sub inspect {
    my $self = shift;

    $self->entity->add_to_state( $self->state );
}

sub need_privilege { 0 }

sub is_current  { $_[0]->state eq 'current' }
sub is_missing  { $_[0]->state eq 'missing' }
sub is_outdated { $_[0]->state eq 'outdated' }

1;
