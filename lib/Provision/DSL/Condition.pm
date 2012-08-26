package Provision::DSL::Condition;
use Moo;
use Carp;

has entity => (
    is => 'ro',
    required => 1,
);

has attribute => (
    is => 'lazy',
);

# must be present in implementation
# sub _build_attribute { }

has value => (
    is => 'ro',
    predicate => 1,
);

# return values as list
sub values {
    my $self = shift;
    
    my $value = $self->value;

    return ref $value eq 'ARRAY'
        ? @$value
        : $value;
}

# must be implemented in implementation
sub state {
    my $self = shift;
    
    croak "calculate_state must be implemented in '${\ref $self}'";
}

1;
