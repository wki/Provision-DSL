package Provision::DSL::Local::RsyncDaemon;
use Moo;
use POSIX ':sys_wait_h';
use Provision::DSL::Const;
use Provision::DSL::Types;

extends 'Provision::DSL::Base';
with 'Provision::DSL::Role::Local',
     'Provision::DSL::Role::CommandAndArgs';

sub DEMOLISH { $_[0]->stop }

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
    default => RSYNC_PORT
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

has pid => (
    is        => 'rw',
    predicate => 1,
    clearer   => 1,
);

sub start {
    my $self = shift;
    
    $self->stop if $self->is_running;
    
    if (my $pid = fork) {
        # parent
        $self->pid($pid);
        
        # must let the daemon try to open the port
        sleep 1;
        
        die "could not start '${\$self->name}' -- port already bound?"
            if waitpid($pid, WNOHANG);
    } else {
        # child
        exec $self->command, @{$self->args};
        
        # never reached, but we are careful...
        exit 1;
    }
}

sub stop {
    my $self = shift;
    
    return if !$self->is_running;
    
    kill 9, $self->pid;
    sleep 1;
    
    $self->clear_pid;
}

sub is_running { $_[0]->has_pid }

1;
