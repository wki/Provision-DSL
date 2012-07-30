package Provision::DSL::Role::CommandExecution;
use Moo::Role;
use Try::Tiny;
use Carp;
use Provision::DSL::Command;

# all commands: $executable [, \%options] , @args

sub command_succeeds {
    my $self       = shift;
    my $executable = shift;
    my %options    = ref $_[0] eq 'HASH' ? %{+shift} : ();
    my @args       = @_;

    my $result;
    try {
        Provision::DSL::Command->new(
            {
                name => $executable,
                args => \@args,
                %options
            }
        )->run;
        $result = 1;
    };

    return $result;
}

sub run_command_as_user {
    my $self       = shift;
    my $executable = shift;
    my %options    = ref $_[0] eq 'HASH' ? %{+shift} : ();

    $self->pipe_into_command(undef, $executable,
        {
            ($self->has_user  ? (user  => $self->user)  : ()),
            ($self->has_group ? (group => $self->group) : ()),
            %options,
        },
        @_
    );
}

sub run_command {
    my $self = shift;

    $self->pipe_into_command(undef, @_);
}

sub pipe_into_command {
    my $self       = shift;
    my $stdin      = shift;
    my $executable = shift;
    my %options    = ref $_[0] eq 'HASH' ? %{+shift} : ();

    my $stdout;
    Provision::DSL::Command->new(
        {
            name   => $executable,
            args   => [ @_ ],
            (defined $stdin ? (stdin  => $stdin) : ()),
            stdout => \$stdout,
            %options
        }
    )->run;

    return $stdout;
}

1;
