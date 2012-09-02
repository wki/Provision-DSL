package Provision::DSL::Role::User;
use Moo::Role;
use Provision::DSL::Types;

has uid => (
    is        => 'ro',
    # coerce    => to_User,
    predicate => 1,
);

# sub _build_user { $< }
# 
# # simulate a predicate
# sub has_user { $_[0]->user->uid != $< }

1;
