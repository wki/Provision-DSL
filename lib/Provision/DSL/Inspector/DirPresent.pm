package Provision::DSL::Inspector::DirPresent;
use Moo;

extends 'Provision::DSL::Inspector';

sub _build_attribute { 'path' }

sub state {
    my $self = shift;
    
    my $attribute = $self->attribute;
    return -d $self->entity->$attribute
        ? 'current'
        : 'missing';
}

sub need_privilege {
    my $self = shift;

    return 1 if $self->entity->has_uid && $self->entity->uid != $<;
    return 1 if $self->entity->has_gid && $self->entity->gid != $(;

    my $dir = $self->value;
    
    if (-d $dir) {
        return __is_not_mine($dir);
    }

    my $ancestor = $dir->parent;
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
