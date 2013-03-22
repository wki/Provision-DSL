package Provision::DSL::Role::Singleton;
use Moo::Role;

my $instance;
sub instance {
    my $class = shift;
    $instance ||= $class->new_with_options(@_);

    return $instance;
}

1;
