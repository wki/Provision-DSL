package Provision::DSL::Role::Provision;
use Moo::Role;

has provision => (
    is       => 'lazy',
    handles  => [
        qw(
            verbose dryrun
            log log_to_file log_dryrun log_debug
        )
    ],
);

sub _build_provision { Provision::DSL::Script::Provision->instance }

1;
