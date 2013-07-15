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
    
    if (!defined $self->path || !-e $self->path) {
        $self->log_info('path missing');
        return 'missing';
    }
    
    if (($self->path->stat->mode & 511) != ($self->permission & 511)) {
        $self->log_info(
            sprintf 'path permisson is %o, should be %o',
                $self->path->stat->mode & 511,
                $self->permission & 511
        );
        return 'outdated';
    }
    
    return 'current';
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
