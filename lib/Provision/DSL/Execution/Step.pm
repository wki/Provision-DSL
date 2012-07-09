package Provision::DSL::Execution::Step;
use Moose;
use Provision::DSL::Types;
use namespace::autoclean;

has entity => (
    is => 'ro',
    isa => 'Entity',
    required => 1,
    handles => [
        'execute',
    ],
);

has priority => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

has execute_before => (
    is => 'ro',
    isa => 'Int',
    predicate => 'has_execute_before',
);

has sort_key => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    lazy_build => 1,
);

sub _build_sort_key {
    my $self = shift;
    
    return $self->has_execute_before
        ? sprintf('%06d/%06d', $self->execute_before-1, $self->priority)
        : sprintf('%06d', $self->priority);
}

__PACKAGE__->meta->make_immutable;
1;
