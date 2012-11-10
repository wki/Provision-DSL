package Provision::DSL::Entity::Execute;
use Moo;
use Cwd;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';
with 'Provision::DSL::Role::CommandExecution';

has path => (
    is     => 'lazy',
    isa    => ExecutableFile,
    coerce => to_ExecutableFile,
);

sub _build_path { $_[0]->name }

has chdir => (
    is        => 'ro',
    isa       => ExistingDir,
    coerce    => to_Dir,
    predicate => 1,
);

has arguments => (
    is      => 'ro',
    default => sub { [] },
    coerce  => to_Array,
);

has args => (
    is     => 'lazy',
    coerce => to_Array,
);

sub _build_args { $_[0]->arguments }

has environment => (
    is      => 'ro',
    default => sub { {} },
);

has env => (
    is => 'lazy',
);

sub _build_env { $_[0]->environment }

# needed to make Execute work like a resource.
sub content { $_[0]->_install }

sub _install {
    my $self = shift;

    my $cwd = getcwd;
    chdir $self->chdir if $self->has_chdir;

    my %extra_opts;
    if ($self->app->verbose) {
        $extra_opts{stdout} = sub { print STDOUT $_[0] };
        $extra_opts{stderr} = sub { print STDERR $_[0] };
    }
    my $script_output = $self->run_command_as_user(
        $self->path->stringify,
        { env => $self->env, %extra_opts },
        @{$self->args},
    );

    chdir $cwd if $self->has_chdir;

    return $script_output;
}

sub create { $_[0]->_install }
sub change { $_[0]->_install }

1;
