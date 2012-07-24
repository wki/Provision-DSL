package Provision::DSL::Role::CommandExecution;
use Moo::Role;
use IPC::Open3 'open3';
use Try::Tiny;
use Carp;

=pod

Just an idea:

my $command => Provision::DSL::Command->new('/usr/bin/ssh');
my $command => Provision::DSL::Command->new('/usr/bin/ssh', { ...} );

my $command = Provision::DSL::Command->new( {
    command => '/usr/bin/ssh',
    args    => [ -f => 'oo', '--bar' ],
    env     => { ... },
    stdin   => 'asdf',
    stdout  => \$ | \&,
    stderr  => \$ | \&,
    
    # using "sudo -n -- command" for command when using:
    user    => user,
    group   => group,
} );

$command->run;

my $status = $command->status;
my $ok = $command->success;         # status == 0

=cut

sub command_succeeds {
    my $self = shift;
    my @args = @_;

    my $result;
    try {
        $self->pipe_into_command('', @args);
        $result = 1;
    };

    return $result;
}

sub system_command {
    my $self = shift;

    return $self->pipe_into_command('', @_);
}

sub pipe_into_command {
    my $self = shift;
    my $input_text = shift;
    my @system_args = @_;

    $self->log_debug('execute:', @system_args);

    my $pid = open3(my $in, my $out, my $err, @system_args);
    print $in $input_text // ();
    close $in;

    my $text = join '', <$out>;
    waitpid $pid, 0;

    my $status = $? >> 8;
    croak "command '@system_args' failed. status: $status" if $status;

    return $text;
}

1;
