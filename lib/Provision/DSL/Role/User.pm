package Provision::DSL::Role::User;
use Moo::Role;
use Provision::DSL::Types;

has user => (
    is        => 'rw',
    coerce    => to_Str,
    predicate => 1,
);

has group => (
    is        => 'rw',
    coerce    => to_Str,
    predicate => 1,
);

sub has_uid { $_[0]->has_user }
sub uid { getpwnam($_[0]->user) }

sub has_gid { $_[0]->has_group }
sub gid { getgrnam($_[0]->group) }

sub is_other_user {
    $_[0]->has_user && $_[0]->user ne getpwuid($<)
}

sub is_other_group {
    $_[0]->has_group && $_[0]->group ne getpwuid($()
}

sub is_other_user_or_group {
    $_[0]->is_other_user || $_[0]->is_other_group
}

1;
