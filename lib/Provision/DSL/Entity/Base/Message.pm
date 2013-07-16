package Provision::DSL::Entity::Base::Message;
use Moo;

# Abstract base class for Message / Note / Info

extends 'Provision::DSL::Entity';

has message => (
    is => 'lazy',
);

sub _build_message { $_[0]->name }

sub _build_default_state { 'outdated' }

sub install {
    my $self = shift;
    
    return if !$self->wanted || $self->state eq 'current';
    
    my $kind = ref $self;
    $kind =~ s{\A .* ::}{}xms;
    
    printf STDERR "*** %s: %s\n", $kind, $self->message;
}

1;
