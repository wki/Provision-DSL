package Provision::DSL::Entity::Base::Package;
use Moo;

extends 'Provision::DSL::Entity';

has installed_version => (
    is        => 'lazy',
    clearer   => 1,
);

has latest_version => (
    is        => 'lazy',
);

sub _build_need_privilege { 1 }

sub inspect {
    my $self = shift;
    
    my $state = 'missing';
    if (!$self->installed_version) {
    } elsif ($self->installed_version ne $self->latest_version) {
        $state = 'outdated';
    } else {
        $state = 'current';
    }
    
    return $state;
}

1;
