package Provision::DSL::Local::RsyncDaemon;
use Moo;
use Provision::DSL::Const;
use Provision::DSL::Types;

extends 'Provision::DSL::Local::Daemon';
with 'Provision::DSL::Role::CommandAndArgs';

sub _build_name { RSYNC }

sub _build_args {
    my $self = shift;

    return [
        '--daemon',
        '--address', '127.0.0.1',
        '--no-detach',
        '--port',   $self->port,
        '--config', $self->rsyncd_config_file->stringify,
    ];
}

has dir => (
    is       => 'ro',
    required => 1,
);

has port => (
    is      => 'ro',
    default => sub { RSYNC_PORT },
);

has rsyncd_config_file => (
    is     => 'lazy',
    coerce => to_File
);

sub _build_rsyncd_config_file {
    my $self = shift;

    my $config_file = $self->dir->file('rsyncd.conf');

    $config_file->spew(<<EOF);
use chroot = no
[local]
    path = ${\$self->dir}
    read only = true
[log]
    path = ${\$self->dir}/log
    read only = false
EOF

    return $config_file;
}

sub start_daemon {
    my $self = shift;

    exec $self->command, @{$self->args};
}

1;
