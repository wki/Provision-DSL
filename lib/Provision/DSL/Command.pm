package Provision::DSL::Command;
use Moo;
use IPC::Run3;
use Provision::DSL::Types;
use Carp;

extends 'Provision::DSL::Base';
# we do not use the user roles, we only need a string as user/group

has user => (
    is => 'ro',
    coerce => to_Str,
    predicate => 1,
);

has group => (
    is => 'ro',
    coerce => to_Str,
    predicate => 1,
);

has command => (
    is => 'lazy',
    coerce => to_Str,
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
    
    my @sudo;
    if ($self->has_user || $self->has_group) {
        @sudo = (
            '/usr/bin/sudo',
            '-n',
            ($self->has_user  ? (-u => $self->user)  : ()),
            ($self->has_group ? (-g => $self->group) : ()),
            '--'
        );
    }
    
    my @command_and_args = (
        @sudo,
        $self->command,
        @{$self->args},
    );
    
    my %old_env = %ENV;
    local %ENV = %old_env;
    @ENV{keys %{$self->env}} = values %{$self->env};
    
    run3 \@command_and_args,
        ($self->has_stdin  ? $self->stdin  : \undef),
        ($self->has_stdout ? $self->stdout : sub {}),
        ($self->has_stderr ? $self->stderr : sub {});

    $self->_status($? >> 8)
        and croak "Nonzero exit status while executing '${\$self->command}'";
    
    if ($self->has_stdout && ref $self->stdout eq 'SCALAR' && defined wantarray) {
        return ${$self->stdout};
    }
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

Provision::DSL::Command - Easy commandline provision

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
