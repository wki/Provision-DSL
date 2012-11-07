package Provision::DSL::Inspector::DirExists;
use Moo;

extends 'Provision::DSL::Inspector';

# sub filter {
#     my ($class, $path) = @_;
#     
#     -d $path;
# }

sub _build_state { 
    (grep { !-d $_ } $_[0]->expected_values) ? 'missing' : 'current' 
}

1;
