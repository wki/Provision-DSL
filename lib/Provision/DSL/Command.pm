package Provision::DSL::Command;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Base';
with 'Provision::DSL::Role::User',
     'Provision::DSL::Role::Group';

has command => (
    is => 'lazy',
    isa => ExecutableFile,
    coerce => to_File,
);

sub _build_command { $_[0]->name }

has args => (
    is => 'ro',
    default => sub { [] },
);

has env => (
    is => 'ro',
    default => sub { {} },
);

has ['stdin', 'stdout', 'stderr'] => (
    is => 'ro',
    predicate => 1,
);

has _status => (
    is => 'rw',
    predicate => '_has_status',
);

sub run {
    
    ### sudo -n when user|group
}

sub status {
    my $self = shift;
    
    return $self->_has_status
        ? $self->_status
        : -1;
}

sub success {
    my $self = shift;
    
    return $self->status == 0;
}

=head1 Provision::DSL::Command

Provision::DSL::Command - Easy commandline execution

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
1;
