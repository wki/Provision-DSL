package Provision::DSL::Inspector::DirExists;
use Moo;

extends 'Provision::DSL::Inspector::Base::Glob';

sub filter {
    my ($class, $path) = @_;
    
    -d $path;
}

sub _build_state { 
    my $self = shift;
    
    foreach my $dir ($self->expected_values) {
        return 'missing' if !-d $dir;
    }
    
    return 'current';
}

1;
