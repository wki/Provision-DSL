package Provision::DSL::Inspector::FilePresent;
use Moo;

extends 'Provision::DSL::Inspector';

sub state {
    my $self = shift;
    
    my $attribute = $self->attribute // 'path';

    return -f $self->entity->$attribute
        ? 'current'
        : 'missing';
}

1;
