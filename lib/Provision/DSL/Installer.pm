package Provision::DSL::Installer;
use Moo;

with 'Provision::DSL::Role::Entity',
     'Provision::DSL::Role::CommandExecution';

sub run_command_maybe_privileged {
    my $self       = shift;
    my $executable = shift;
    my %options    = ref $_[0] eq 'HASH' ? %{+shift} : ();

    $options{user} = 'root' if $self->entity->need_privilege;

    $self->run_command($executable, \%options, @_);
}

sub create {}
sub change {}
sub remove {}

1;
