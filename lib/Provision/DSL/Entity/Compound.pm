package Provision::DSL::Entity::Compound;
use Moo;
use Provision::DSL::Types;
use List::MoreUtils qw(any all none);

extends 'Provision::DSL::Entity';

has children => (
    is => 'lazy',
    # default => sub { [] },
    # handles => {
    #     all_children    => 'elements',
    #     add_child       => 'push',
    #     has_no_children => 'is_empty',
    # },
);

sub _build_children { [] }

sub add_child {
    my $self = shift;
    
    push @{$self->children}, @_;
}

sub all_children { @{$_[0]->children} }

sub has_no_children { !scalar @{$_[0]->children} }

around is_present => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(@_)
        && ($self->has_no_children
            || any { $_->is_present } $self->all_children);
};

around is_current => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(@_) 
        && all { $_->is_current } $self->all_children;
};

sub create { $_->execute(1) for $_[0]->all_children }
sub change { $_->execute(1) for $_[0]->all_children }
sub remove { $_->execute(0) for reverse $_[0]->all_children }

1;
