package Provision::DSL::Role::CommandExecution;
use Moo::Role;
use Try::Tiny;
use Carp;
use Provision::DSL::Command;

sub command_succeeds {
    my ($self, $executable, @args) = @_;

    my $result;
    try {
        Provision::DSL::Command->new($executable, { args => \@args })->run;
        $result = 1;
    };

    return $result;
}

sub system_command {
    my ($self, $executable, @args) = @_;

    my $stdout;
    Provision::DSL::Command->new($executable,
        {
            args   => \@args,
            stdout => \$stdout,
        })->run;

    return $stdout;
}

sub pipe_into_command {
    my ($self, $stdin, $executable, @args) = @_;

    my $stdout;
    Provision::DSL::Command->new($executable,
        {
            args   => \@args,
            stdin  => $stdin,
            stdout => \$stdout,
        })->run;

    return $stdout;
}

1;
