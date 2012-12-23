package Provision::DSL::Role::App;
use Moo::Role;
use Provision::DSL::App;

has app => (
    is       => 'lazy',
    handles  => [
        qw(
            verbose dryrun
            log log_to_file log_dryrun log_debug
            create_entity
            user_has_privilege
            run_command pipe_into_command command_succeeds
        )
        # FIXME: can we safely remove *command* methods above?
    ],
);

sub _build_app { Provision::DSL::App->instance }

1;
