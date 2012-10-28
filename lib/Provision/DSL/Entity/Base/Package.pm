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
    } elsif ($self->wanted eq 'latest' && $self->installed_version ne $self->latest_version) {
        $state = 'outdated';
    } elsif ($self->wanted ne '1' && $self->installed_version ne $self->wanted) {
        $state = 'outdated';
    } else {
        $state = 'current';
    }
    
    return $state;
}

1;
