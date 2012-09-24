package Provision::DSL::Entity::_Ubuntu::Package;
use Moo;
use Try::Tiny;

extends 'Provision::DSL::Entity::Package';
with 'Provision::DSL::Role::CommandExecution';

our $DPKG_QUERY = '/usr/bin/dpkg-query';
our $APTITUDE   = '/usr/bin/aptitude';

sub change { goto \&create }
sub create {
    my $self = shift;

    $self->run_command_as_superuser(
        $APTITUDE,
        '--assume-yes',
        install => $self->name,
    );
    $self->clear_installed_version;
}

sub remove {
    my $self = shift;

    $self->run_command_as_superuser(
        $APTITUDE,
        purge => $self->name,
    );
    $self->clear_installed_version;
}

sub _build_installed_version {
    my $self = shift;

    my $result = $self->run_command(
        $DPKG_QUERY,
        '--show',
        '--showformat', '${Package}\\t${Version}\\t${Status}',
        $self->name,
    );

    my ($package, $version, $status) = split qr{\t}, $result;

    return $version;
}

sub _build_latest_version {
    my $self = shift;

    my $result = 
        $self->run_command(
            $APTITUDE, 
            '--group-by' => 'none',
            '--disable-columns',
            '--display-format', '%p',
            'versions' => sprintf('?name(%s)', quotemeta($self->name))
        );
    
    my $latest_version = '';
    foreach my $line (split /\n/, $result) {
        next if ($line !~ m{\A (\Q${\$self->name}\E) \s+
                               (\S+)}xms);
        my ($name, $version) = ($1, $2);
        
        if ($version gt $latest_version) {
            $latest_version = $version;
        }
    }
    
    die "package '${\$self->{name}}' not found" if !$latest_version;
    
    return $latest_version;
}

1;
