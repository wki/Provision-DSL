package Provision::DSL::Role::Singleton;
use Moo::Role;

around new => sub {
    my ($orig, $class, @args) = @_;

    ### is it clean to check for instance() in call hierarchy?
    for (my $i = 0; $i < 10; $i++) {
        my ($package, $filename, $line, $sub) = caller($i);

        next if !$sub || $sub !~ m{:: instance \z}xms;

        return $class->$orig(@args);
    }

    die 'Singleton: calling new directly is forbidden';
};

my $instance;
sub instance {
    my $class = shift;
    $instance ||= $class->new_with_options(@_);

    return $instance;
}

1;
