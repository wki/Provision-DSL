package Provision::DSL::Entity::Path::Permission;
use Moo;
use Carp;
use Provision::DSL::Const;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::Path';

has path => (
    is => 'ro',
    required => 1,
);

sub inspect { 
    my $self = shift;
    
    return 'missing' if !defined $self->path || !-e $self->path;
    return ($self->path->stat->mode & 511) != ($self->permission & 511)
        ? 'outdated'
        : 'current'
}

sub create { goto \&change }
sub change {
    my $self = shift;
    
    $self->run_command_maybe_privileged(
        CHMOD,
        sprintf('%3o', $self->permission),
        $self->path,
    );
}

1;
