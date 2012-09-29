package Provision::DSL::Installer;
use Moo;

with 'Provision::DSL::Role::Entity',
     'Provision::DSL::Role::CommandExecution';

sub create {}
sub change {}
sub remove {}

1;
