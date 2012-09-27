package Provision::DSL::Entity::_Ubuntu::Service;
use Moo;

extends 'Provision::DSL::Entity::Service';

sub BUILD {
    my $self = shift;

    $self->add_children(
        $self->__service_rc,
        $self->__service_process,
    );
}

sub _build_permission { '0755' }
sub _build_path       { "/etc/init.d/${\$_[0]->name}" }
sub _build_user       { 'root' }
sub _build_group      { 'root' }

sub _build_need_privilege { 1 }

sub __service_process {
    my $self = shift;

    return $self->create_entity(
        Service_Process => {
            parent   => $self,
            name     => $self->path->stringify,
            ($self->has_pid_file
                ? (pid_file => $self->pid_file)
                : ()),
        }
    );
}

sub __service_rc {
    my $self = shift;

    return $self->create_entity(
        Service_Rc => {
            parent   => $self,
            name     => $self->name,
        },
    );
}

1;

__END__

/etc/init.d --> service-datei falls gewuenscht.
/etc/rcX.d  --> je nach runlevel

evtl. schon vorhanden.
/sbin/start-stop-daemon verwenden!

/usr/sbin/update-rc.d -- zum Ändern des runlevel

STATUS:
service nginx status   --> läuft oder nicht (exit-code > 0: läuft nicht)

HALT:
update-rc.d -f nginx remove; service nginx stop

START:
update-rc.d -f nginx defaults: service nginx start


