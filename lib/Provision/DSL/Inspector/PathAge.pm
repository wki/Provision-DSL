package Provision::DSL::Inspector::PathAge;
use Moo;
use Path::Class;

extends 'Provision::DSL::Inspector';

sub _build_attribute { 'path' }

sub _build_state {
    my $self = shift;
    
    my $destination_file = $self->value;
    
    return 'missing' if !-e $destination_file;

    my $destination_timestamp = $destination_file->stat->mtime;
    foreach my $compare_file (map { file($_) } $self->expected_values) {
        next if !-f $compare_file;
        next if $compare_file->stat->mtime <= $destination_timestamp;
        
        return 'outdated';
    }
    
    return 'current';
}

1;
