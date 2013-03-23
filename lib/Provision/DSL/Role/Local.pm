package Provision::DSL::Role::Local;
use Moo::Role;

has app => (
    is       => 'lazy',
    handles  => [
        qw(
            verbose dryrun
            log log_to_file log_dryrun log_debug
            root_dir config
        )
    ],
);

sub _build_app { Provision::DSL::Local->instance }

1;
