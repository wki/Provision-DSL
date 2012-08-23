package Provision::DSL::Role::Group;
use Moo::Role;
use Provision::DSL::Types;

has group => (
    is     => 'lazy',
    coerce => to_Group,
);

sub _build_group { $(+0 }

# simulate a predicate
sub has_group { $_[0]->group->gid != $( }

1;
