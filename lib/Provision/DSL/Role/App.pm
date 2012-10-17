package Provision::DSL::Role::App;
use Moo::Role;
use Provision::DSL::App;

has app => (
    is       => 'lazy',
    handles  => [
        qw(
            verbose dryrun
            log log_dryrun log_debug
            create_entity
            user_has_privilege
            run_command pipe_into_command command_succeeds
        )
    ],
);

sub _build_app { Provision::DSL::App->instance }

1;
