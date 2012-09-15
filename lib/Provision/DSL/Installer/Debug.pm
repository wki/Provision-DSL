package Provision::DSL::Installer::Debug;
use Moose;
use namespace::autoclean;

extends 'Provision::DSL::Installer';

has debug_info => (
    is => 'rw',
    default => sub { '' },
);

sub create { $_[0]->debug_info('create') }
sub change { $_[0]->debug_info('change') }
sub remove { $_[0]->debug_info('remove') }

1;
