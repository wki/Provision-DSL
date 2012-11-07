package Provision::DSL::Inspector::FileExists;
use Moo;

extends 'Provision::DSL::Inspector::Base::Glob';

sub filter {
    my ($class, $path) = @_;
    
    -f $path;
}

sub _build_state { 
    my $self = shift;
    
    foreach my $file ($self->expected_values) {
        return 'missing' if !-f $file || -l $file;
    }
    
    return 'current';
}

1;
