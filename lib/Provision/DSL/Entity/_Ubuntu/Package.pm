package Provision::DSL::Entity::_Ubuntu::Package;
use Moo;

extends 'Provision::DSL::Entity::Package';

around is_ok => sub {
    my ($orig, $self) = @_;

    return $self->_installed_version && $self->$orig();
};

before create => sub {
    my $self = shift;

    ...
};

after remove => sub {
    my $self = shift;

    ...
};

sub _installed_version {
    my $self = shift;

    ...
}

sub _latest_version {
    my $self = shift;

    ...
}

1;
