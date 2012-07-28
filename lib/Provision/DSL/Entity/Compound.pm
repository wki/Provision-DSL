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

before state => sub {
    my $self = shift;
    
    $self->add_state($_->is_ok ? 'current' : 'outdated')
        for $self->add_children;
};

# only remove() receives wanted=0, all others use their own wanted attribute
after ['create', 'change']
    => sub { $_->execute()  for         $_[0]->all_children };

before remove
    => sub { $_->execute(0) for reverse $_[0]->all_children };

1;
