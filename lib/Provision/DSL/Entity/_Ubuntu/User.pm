package Provision::DSL::Entity::_Ubuntu::User;
use Moo;

extends 'Provision::DSL::Entity::User';

sub _build_home_directory {
    my $self = shift;
    
    return (getpwuid($self->uid))[7] // "/home/${\$self->name}"; # /
}

before create => sub {
    my $self = shift;

    ...
};

1;
