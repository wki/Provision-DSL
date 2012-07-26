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

around state => sub {
    my $orig = shift;
    my $self = shift;
    
    # if ($self->nr_children) {
    #     my $nr_children_ok = scalar grep { $_->is_ok } $self->all_children;
    #     
    # }
    
    return $self->$orig(@_) if $self->has_no_children;
    
    # count children being OK versus children reporting being not-ok
    my $nr_children_ok = scalar grep { $_->is_ok } $self->all_children;
    
    my $state = $nr_children_ok == $self->nr_children
        ? 'current'
        : 'outdated';
    
    return $self->$orig($state, @_);
};

# only remove() receives wanted=0, all others use their own wanted attribute
after ['create', 'change']
    => sub { $_->execute()  for         $_[0]->all_children };

before remove
    => sub { $_->execute(0) for reverse $_[0]->all_children };

1;
