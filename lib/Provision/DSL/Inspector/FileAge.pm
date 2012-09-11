package Provision::DSL::Inspector::FileAge;
use Moo;
use Path::Class;

extends 'Provision::DSL::Inspector';

sub _build_attribute { 'path' }

sub state {
    my $self = shift;
    
    my $state = 'current';
    my $attribute = $self->attribute // 'path';
    my $destination_file = $self->entity->$attribute;
    
    return 'missing' if !-e $destination_file;

    my $destination_timestamp = $destination_file->stat->mtime;
    foreach my $compare_file (map { file($_) } $self->values) {
        next if !-f $compare_file;
        next if $compare_file->state->mtime <= $destination_timestamp;
        
        return 'outdated';
    }
}

1;
