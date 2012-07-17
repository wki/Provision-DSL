package Provision::DSL::Entity::Compound;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';

has children => (
    is => 'lazy',
);

sub _build_children { [] }

sub add_child {
    my $self = shift;

    push @{$self->children}, @_;
}

sub nr_children { scalar @{$_[0]->children} }

sub all_children { @{$_[0]->children} }

sub has_no_children { !scalar @{$_[0]->children} }

around is_ok => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(@_)
        && scalar(grep { $_->is_ok } $self->all_children) == $self->nr_children;
};

# only remove() receives wanted=0, all others use their own wanted attribute
after create => sub { $_->execute()  for         $_[0]->all_children };
after remove => sub { $_->execute(0) for reverse $_[0]->all_children };

1;
