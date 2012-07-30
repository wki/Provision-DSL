package Provision::DSL::Entity::_OSX::Group;
use Moo;

extends 'Provision::DSL::Entity::Group';

our $DSCL = '/usr/bin/dscl';

before create => sub {
    my $self = shift;

    my $group = "/Groups/${\$self->name}";

    $self->app->run_command($DSCL, '.', -create => $group); 
    $self->app->run_command($DSCL, '.', -append => $group,
                          PrimaryGroupID => $self->gid);
};

after remove => sub {
    my $self = shift;
    
    my $members = (getgrgid($self->gid))[3];
    die "Cannot remove group ${\$self->name}: in use by '$members'" if $members;
    
    $self->app->run_command($DSCL, '.', -delete => "/Groups/${\$self->name}");
};

1;
