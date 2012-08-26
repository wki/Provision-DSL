package Provision::DSL::Condition::DirPresent;
use Moo;

extends 'Provision::DSL::Condition';

sub state {
    my $self = shift;
    
    my $attribute = $self->attribute // 'path';
    return -d $self->entity->$attribute
        ? 'current'
        : 'missing';
}

1;
