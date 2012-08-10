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

before calculate_state => sub {
    my $self = shift;
    
    my $installed = $self->installed_version;
    if (!$installed) {
        $self->add_to_state('missing');
    } elsif ($installed ne $self->latest_version) {
        $self->add_to_state('outdated');
    } else {
        $self->add_to_state('current');
    }
};

1;
