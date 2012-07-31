package Provision::DSL::Entity::_Ubuntu::Package;
use Moo;

extends 'Provision::DSL::Entity::Package';
with 'Provision::DSL::Role::CommandExecution';

our $DPKG_Q   = '/usr/bin/dpkg-query';
our $APTITUDE = '/usr/bin/aptitude';

before ['create','change'] => sub {
    my $self = shift;

    $self->run_command($APTITUDE,
                       { user => 'root' },
                       install => $self->name);
    $self->clear_installed_version;
};

after remove => sub {
    my $self = shift;

    $self->run_command($APTITUDE,
                       { user => 'root' },
                       remove => $self->name);
    $self->clear_installed_version;
};

sub _build_installed_version {
    my $self = shift;

    my ($name, $version, $dummy) =
        split qr/\s+/,
              $self->run_command($DPKG_Q, '--show' => $self->name);

    return $version;
}

sub _build_latest_version {
    my $self = shift;

    my $result = 
        $self->run_command($APTITUDE, 
                           '--group-by' => 'none',
                           'versions'   => $self->name);
    
    my $last_prio = -1;
    my $latest_version;
    foreach my $line (split /\n/, $result) {
        my ($status, $name, $version, $release, $prio) = split qr/\s+/, $line;
        if ($prio > $last_prio) {
            $latest_version = $version;
            $last_prio = $prio;
        }
    }
    
    die "package '${\$self->{name}}' not found" if !$latest_version;
    
    return $latest_version;
}

1;
