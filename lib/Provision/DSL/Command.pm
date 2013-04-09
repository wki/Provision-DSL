package Provision::DSL::Command;
use Moo;
use IPC::Run3;
use Provision::DSL::Types;
use Provision::DSL::Const;
use Carp;

extends 'Provision::DSL::Base';
with 'Provision::DSL::Role::User',
     'Provision::DSL::Role::CommandAndArgs';

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
    if ($self->is_other_user_or_group) {
        @sudo = (
            SUDO,
            '-n',
            ### FIXME: under Linux, `sudo -n -u user cmd` does not seem to work sometimes
            ###        instead `sudo -n sudo -u user cmd` works.
            ($self->is_other_user  ? (-u => $self->user)  : ()),
            ($self->is_other_group ? (-g => $self->group) : ()),
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
    
    my ($stdout, $stderr);
    run3 \@command_and_args,
        ($self->has_stdin  ? $self->stdin  : \undef),
        ($self->has_stdout ? $self->stdout : \$stdout),
        ($self->has_stderr ? $self->stderr : \$stderr);

    $self->_status($? >> 8)
        and croak "Nonzero exit status while executing '${\$self->command}', STDERR: $stderr";
    
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

Provision::DSL::Command - Easy command execution

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
