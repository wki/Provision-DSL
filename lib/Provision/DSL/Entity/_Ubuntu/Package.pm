package Provision::DSL::Entity::_Ubuntu::Package;
use Moo;
use Try::Tiny;

extends 'Provision::DSL::Entity::Package';
with 'Provision::DSL::Role::CommandExecution';

our $DPKG_QUERY = '/usr/bin/dpkg-query';
our $APTITUDE   = '/usr/bin/aptitude';

before ['create','change'] => sub {
    my $self = shift;

    $self->run_command($APTITUDE,
                       { user => 'root' },
                       '--assume-yes',
                       install => $self->name);
    $self->clear_installed_version;
};

after remove => sub {
    my $self = shift;

    $self->run_command($APTITUDE,
                       { user => 'root' },
                       purge => $self->name);
    $self->clear_installed_version;
};

sub _build_installed_version {
    my $self = shift;

    my ($name, $version, $dummy);
    try {
        ($name, $version, $dummy) =
            split qr/\s+/,
                  $self->run_command($DPKG_QUERY, '--show' => $self->name);
        # warn "INSTALLED: $name VERSION: $version";
    } catch {
        $version = 0;
    };

    return $version;
}

sub _build_latest_version {
    my $self = shift;

    my $result = 
        $self->run_command($APTITUDE, 
                           '--group-by' => 'none',
                           'versions'   => $self->name);
    
    my $last_prio = -1;
    my $latest_version = '';
    foreach my $line (split /\n/, $result) {
        next if ($line !~ m{\A (.+?) \s+ 
                               (\Q${\$self->name}\E .*?) \s+
                               (\S+) \s+
                               (\S+) \s+
                               (\S+)}xms);
        my ($status, $name, $version, $release, $prio) = ($1, $2, $3, $4, $5);
        
        if ($prio > $last_prio || $version gt $latest_version) {
            $latest_version = $version;
            $last_prio = $prio;
        }
    }
    
    # warn "LATEST: $latest_version";
    die "package '${\$self->{name}}' not found" if !$latest_version;
    
    return $latest_version;
}

1;
