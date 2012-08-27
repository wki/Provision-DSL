package Provision::DSL::Inspector::DirPresent;
use Moo;

extends 'Provision::DSL::Inspector';

sub state {
    my $self = shift;
    
    my $attribute = $self->attribute // 'path';
    return -d $self->entity->$attribute
        ? 'current'
        : 'missing';
}

1;
