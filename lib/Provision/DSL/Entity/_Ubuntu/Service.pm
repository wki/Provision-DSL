package Provision::DSL::Entity::_Ubuntu::Service;
use Moo;

extends 'Provision::DSL::Entity::Service';

our $SERVICE    = '/usr/sbin/service';
our $UPDATE_RCD = '/usr/sbin/update-rc.d';

sub _build_permission { '0777' }
sub _build_path       { "/etc/init.d/${\$_[0]->name}" }
sub _build_user       { 'root' }
sub _build_group      { 'root' }

sub _build_need_privilege { 1 }

sub _service_running {
    my $self = shift;
    
    $self->command_succeeds(
        $SERVICE,
        $self->name, 'status',
    )
}

sub _install_service {
    my $self = shift;
    
    $self->run_command_as_superuser(
        $UPDATE_RCD,
        '-f',
        $self->name, 'defaults',
    );
}

sub _stop_service  { $_->__service('stop') }
sub _start_service { $_->__service('start') }

sub __service {
    my ($self, $action) = @_;
    
    $self->run_command_as_superuser(
        $SERVICE,
        $self->name, $action,
    );
}

around _build_children => sub {
    my $orig = shift;
    my $self = shift;
    
    my $children = $self->$orig();
    
    # TODO: push @$children, 'Daemon';

    return $children;
};

#
# /etc/init.d --> service-datei falls gewuenscht.
# /etc/rcX.d  --> je nach runlevel
#
# evtl. schon vorhanden.
# /sbin/start-stop-daemon verwenden!

# /usr/sbin/update-rc.d -- zum Ändern des runlevel
#
# STATUS:
# service nginx status   --> läuft oder nicht (exit-code > 0: läuft nicht)
#
# HALT:
# update-rc.d -f nginx remove; service nginx stop
#
# START:
# update-rc.d -f nginx defaults: service nginx start
#
#

1;
