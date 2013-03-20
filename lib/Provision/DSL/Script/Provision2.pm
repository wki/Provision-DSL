package Provision::DSL::Script::Provision2;
use Moo;
use Provision::DSL::Script::Config;
use Provision::DSL::Script::Requisites;
use Provision::DSL::Script::Resources;
use Provision::DSL::Script::DSL;
use Provision::DSL::Script::Remote;
use Provision::DSL::Script::RsyncDaemon;
use Provision::DSL::Script::Timer;

# basic attributes, configurable via commandline-options
has hostname => ();
has user => ();
has provision_file => ();
has archname => ();
has config_file => ();

# aggregations with lazy build
has config => ();
sub _build_config {}

has requisites => ();
sub _build_requisites {}

has resources => ();
sub _build_resources {}

has dsl => ();
sub _build_dsl {}

has remote => ();
sub _build_remote {}

has rsync_deamon => ();
sub _build_rsync_daemon {}

has timer => ();
sub _build_timer {}

# directories with lazy build
has root_dir => ();
has cache_dir => ();

sub run {
    my $self = shift;

    $self->requisites->build;
    $self->resources->build;

    $self->dsl->must_have_valid_syntax;

    $self->rsync_daemon->start;

    $self->remote->pull_requisites($self->requisites->dir);
    $self->remote->pull_resources($self->resources->dir);
    $self->remote->execute_dsl;
    $self->remote->push_logs;

    $self->rsync_daemon->stop;
}

1;
