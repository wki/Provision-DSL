package Provision::DSL::Entity::Link;
use Moo;
# use Carp;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::File';

has link_to => (
    is => 'ro',
    required => 1,
    coerce => to_File,
);

sub inspect {
    -l $_[0]->path && readlink $_[0]->path eq $_[0]->link_to
        ? 'current'
        : 'missing'
}

sub change { goto \&create }
sub create {
    my $self = shift;

    $self->prepare_for_creation;

    $self->run_command_maybe_privileged(
        '/bin/ln',
        '-s', $self->link_to, $self->path
    );
}

1;
