package Provision::DSL::Installer;
use Moo;
use Carp;

with 'Provision::DSL::Role::Entity';

sub create {}
sub change {}
sub remove {}

1;
