package Provision::DSL::Role::CommandExecution;
use Moo::Role;
use Carp;
use Provision::DSL::Const 'CAT'; # otherwise Role::Tiny complains.
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

sub run_command_maybe_privileged {
    my $self       = shift;
    my $executable = shift;
    my %options    = ref $_[0] eq 'HASH' ? %{+shift} : ();

    $options{user} = 'root'
        if $self->can('need_privilege')
           && $self->need_privilege;

    $self->run_command($executable, \%options, @_);
}

sub run_command_as_superuser {
    my $self       = shift;
    my $executable = shift;
    my %options    = ref $_[0] eq 'HASH' ? %{+shift} : ();

    $options{user} = 'root';
    
    $self->run_command($executable, \%options, @_);
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
                    $options{$attribute} = $entity->$attribute;
                    # $options{$attribute} = $entity->$attribute->name;
                }
                next ATTRIBUTE;
            } else {
                $entity = $entity->parent;
            }
        }
    }

    $self->run_command($executable, \%options, @_);
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

    # warn "command: $executable " . join(' ', @_);
    my $stdout;
    Provision::DSL::Command->new(
        {
            name   => $executable,
            args   => [ @_ ],
            (defined $stdin ? (stdin  => \$stdin) : ()),
            stdout => \$stdout,
            %options
        }
    )->run;
    
    return $stdout;
}

sub read_content_of_file {
    my $self = shift;
    my $file = shift;
    
    return $self->run_command_maybe_privileged(CAT, $file);
}

1;
