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

sub state {
    my $self = shift;
    
    return $self->default_state if $self->has_no_children;
    
    # count children being OK versus children reporting being not-ok
    my $nr_children_ok = scalar grep { $_->is_ok } $self->all_children;
    
    return $nr_children_ok == $self->nr_children
        ? 'current'
        : 'outdated';
    
    # WRONG:
    # # only considering children states.
    # # must use around state in child class to expand
    # my %seen_state =
    #     map { ($_->state => 1) }
    #     $self->all_children;
    # 
    # return scalar keys %seen_state == 1
    #     ? (keys %seen_state)[0]
    #     : 'outdated';
};

# only remove() receives wanted=0, all others use their own wanted attribute
after ['create', 'change']
    => sub { $_->execute()  for         $_[0]->all_children };

before remove
    => sub { $_->execute(0) for reverse $_[0]->all_children };

1;
