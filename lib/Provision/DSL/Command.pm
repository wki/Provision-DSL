package Provision::DSL::Command;
use Moo;
use IPC::Run3;
use Provision::DSL::Types;
use Carp;

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

has stdin => (
    is => 'ro',
    predicate => 1,
);

has stdout => (
    is => 'ro',
    predicate => 1,
);

has stderr => (
    is => 'ro',
    predicate => 1,
);

has _status => (
    is => 'rw',
    predicate => '_has_status',
);

sub run {
    my $self = shift;
    
    ### TODO: /usr/bin/sudo -n  -u | -g when user|group
    my @command_and_args = (
        $self->command->stringify,
        @{$self->args},
    );
    
    local %ENV;
    @ENV{keys %{$self->env}} = values %{$self->env};
    
    run3 \@command_and_args,
        ($self->has_stdin  ? $self->stdin  : \undef),
        ($self->has_stdout ? $self->stdout : sub {}),
        ($self->has_stderr ? $self->stderr : sub {});

    $self->_status($? >> 8)
        and croak "Nonzero exit status while executing '${\$self->command}'";
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
