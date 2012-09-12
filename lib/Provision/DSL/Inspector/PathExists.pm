package Provision::DSL::Inspector::PathExists;
use Moo;

extends 'Provision::DSL::Inspector';

sub _build_attribute { 'path' }

sub state { -e $_[0]->value ? 'current' : 'missing' }

sub need_privilege {
    my $self = shift;

    return 1 if $self->entity->has_user  && $self->entity->uid != $<;
    return 1 if $self->entity->has_group && $self->entity->gid != $(;

    my $path = $self->value;
    
    if (-e $path) {
        return __is_not_mine($path);
    }

    my $ancestor = $path->parent;
    while (!-d $ancestor && scalar $ancestor->dir_list > 1) {
        $ancestor = $ancestor->parent;
    }

    return __is_not_mine($ancestor);
}

sub __is_not_mine {
    my $path = shift;

    my $stat = $path->stat;
    return $stat->uid != $< || $stat->gid != $(;
}

1;
