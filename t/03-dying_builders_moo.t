use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package X;
    use Moo;
    
    has value => (
        is        => 'rw',
        clearer   => 1,
        predicate => 1,
    );
    
    has attr => (
        is        => 'lazy',
        clearer   => 1,
        predicate => 1,
    );
    
    sub _build_attr {
        my $self = shift;
        
        die 'missing value' if !$self->has_value;
        return $self->value;
    }
}

my $x = X->new;

ok !$x->has_attr, 'initially no attr';
dies_ok { my $foo = $x->attr } 'building dies w/o value';
ok !$x->has_attr, 'no attr after builder died';

$x->value(42);
lives_ok { my $foo = $x->attr } 'building lives w/ value';
ok $x->has_attr, 'attr after builder survived';

done_testing;
