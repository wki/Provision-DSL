package Provision::DSL::Condition::FilePresent;
use Moo;

extends 'Provision::DSL::Condition';

sub state {
    my $self = shift;
    
    my $attribute = $self->attribute // 'path';

    return -f $self->entity->$attribute
        ? 'current'
        : 'missing';
}

1;
