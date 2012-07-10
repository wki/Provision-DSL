package Provision::DSL::Entity::Execute;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';

has path => (
    is => 'lazy',
    # isa => 'ExecutableFile',
    # coerce => 1,
    # required => 1,
    # lazy_build => 1,
);

sub _build_path { $_[0]->name }

has arguments => (
    is => 'ro',
    # isa => 'ArrayRef',
    default => sub { [] },
);

after create => sub { 
    my $self = shift;
    
    $self->system_command($self->path, @{$self->arguments}),
};

1;
