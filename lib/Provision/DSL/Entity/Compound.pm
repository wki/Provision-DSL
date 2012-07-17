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

# return a true value if compound has a state by itself
sub compound_state { }

sub state {
    my $self = shift;

    my $state = $self->compound_state;
    return $state || $self->default_state if $self->has_no_children;
    
    my %seen_state =
        ($state ? ($state => 1) : ()),
        map { ($_->state => 1) }
        $self->all_children;

    return scalar keys %seen_state == 1
        ? (keys %seen_state)[0]
        : 'outdated';
};

# only remove() receives wanted=0, all others use their own wanted attribute
after ['create', 'change']
    => sub { $_->execute()  for         $_[0]->all_children };

before remove
    => sub { $_->execute(0) for reverse $_[0]->all_children };

1;
