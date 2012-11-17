package Provision::DSL::LazyEntity;
use Moo;
use Try::Tiny;

extends 'Provision::DSL::Base';

has package => (
    is => 'ro',
    required => 1,
);

has args => (
    is => 'ro',
    required => 1,
);

has _instance => (
    is => 'rw',
    predicate => 1,
);

sub instance {
    my $self = shift;
    
    $self->_ensure_instance_exists;
    return $self->_instance;
}

sub _ensure_instance_exists {
    my $self = shift;
    
    return if $self->_has_instance;
    $self->_instance($self->package->new($self->args));
}

sub _build_name { $_->[0]->args->{name} }

# trap all methods and forward them to our instance
sub AUTOLOAD {
    my $self = shift;
    
    my $method = $AUTOLOAD;
    $method =~ s{\A .* ::}{}xms;
    
    $self->instance->$method(@_);
}

# returns undef in case of instantiation failure, result otherwise
sub carefully_call {
    my $self   = shift;
    my $method = shift;
    
    try {
        $self->_ensure_instance_exists;
    };
    
    return if !$self->_has_instance;
    $self->instance->$method(@_);
}

1;
