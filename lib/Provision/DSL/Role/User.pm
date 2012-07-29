package Provision::DSL::Role::User;
use Moo::Role;
use Provision::DSL::Types;

has user => (
    is => 'lazy',
    coerce => to_User,
);

sub _build_user { $< }

# simulate a predicate
sub has_user { $_[0]->user->uid != $< }

1;
