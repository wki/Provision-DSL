package Provision::DSL::Entity::_OSX::Package;
use Moo;

extends 'Provision::DSL::Entity::Package';

my $PORT = '/opt/local/bin/port';

around is_ok => sub {
    my ($orig, $self) = @_;

    ### FIXME: compare against latest version
    return $self->_installed_version && $self->$orig();
};

before create => sub {
    my $self = shift;

    $self->run_command($PORT, install => $self->name);
};

after remove => sub {
    my $self = shift;

    $self->run_command($PORT, uninstall => $self->name);
};

sub _installed_version {
    my $self = shift;

    my ($installed_version) =
    map { m{\A \s* \Q${\$self->name}\E \s+ (\S+)_\d+ .* active}xms ? $1 : () }
    `$PORT installed`;

    return $installed_version;
}

sub _latest_version {
    my $self = shift;

    my ($latest_version) =
        map { m{\A \s* \S+ \s+ (\S+)}xms ? $1 : () }
        `$PORT info --line ${\$self->name}`;

    return $latest_version;
}

1;
