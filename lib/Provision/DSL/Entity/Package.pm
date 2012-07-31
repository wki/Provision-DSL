package Provision::DSL::Entity::Package;
use Moo;

extends 'Provision::DSL::Entity';

has installed_version => (
    is        => 'lazy',
    clearer   => 1,
);

has latest_version => (
    is        => 'lazy',
);

before state => sub {
    my $self = shift;
    
    my $installed = $self->installed_version;
    if (!$installed) {
        $self->set_state('missing');
    } elsif ($installed ne $self->latest_version) {
        $self->set_state('outdated');
    } else {
        $self->set_state('current');
    }
};

1;
