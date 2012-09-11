package Provision::DSL::Role::CommandExecution;
use Moo::Role;
use Carp;
use Provision::DSL::Command;

# all commands: $executable [, \%options] , @args

sub command_succeeds {
    my $self = shift;

    my $result;
    eval {
        $self->run_command(@_);
        $result = 1;
    };

    return $result;
}

sub run_command_as_superuser {
    my $self       = shift;
    my $executable = shift;
    my %options    = ref $_[0] eq 'HASH' ? %{+shift} : ();

    $self->pipe_into_command(
        undef,
        '/usr/bin/sudo',
        \%options,
        '-n',
        '-u' => 'root',
        $executable,
        @_);
}

sub run_command_as_user {
    my $self       = shift;
    my $executable = shift;
    my %options    = ref $_[0] eq 'HASH' ? %{+shift} : ();
    
    ATTRIBUTE:
    foreach my $attribute (qw(user group)) {
        my $predicate = "has_$attribute";
        my $entity = $self;
        while ($entity) {
            if ($entity->can($attribute)) {
                if ($entity->$predicate) {
                    $options{$attribute} = $entity->$attribute->name;
                }
                next ATTRIBUTE;
            } else {
                $entity = $entity->parent;
            }
        }
    }

    $self->pipe_into_command(undef, $executable, \%options, @_);
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
