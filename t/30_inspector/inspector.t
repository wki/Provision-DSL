use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
require "$FindBin::Bin/../inc/mock_entity.pm";

use ok 'Provision::DSL::Inspector';

dies_ok { Provision::DSL::Inspector->new }
        'inspector creation without entity dies';

# state handling
{
    my $e = E->new;
    my $i = Provision::DSL::Inspector->new( entity => $e );
    
    dies_ok { $i->state }
            'Inspector base class does not have a state builder';
}

# value from entity's attribute
{
    my $e = E->new(path => 42);
    my $i = Provision::DSL::Inspector->new(
        entity => $e,
        attribute => 'path',
    );
    
    is $i->value, 42, "value read from entitie's attribute";
    is_deeply [$i->values], [42], 'value in plural OK';
    
    $e->path([1,2,3]);
    is_deeply $i->value, [1,2,3], "array-ref value";
    is_deeply [$i->values], [1,2,3], 'array-ref value in plural OK';
}

# expected value handling
{
    my $e = E->new;
    my $i = Provision::DSL::Inspector->new( entity => $e );
    $i = Provision::DSL::Inspector->new( entity => $e, expected_value => 42 );
    is_deeply [$i->expected_values], [42], 'values are expanded from scalar';
    
    $i = Provision::DSL::Inspector->new( entity => $e, expected_value => [42,43] );
    is_deeply [$i->expected_values], [42,43], 'values are expanded from arrayref';
    
    dies_ok { Provision::DSL::Inspector->new( entity => $e, state => 'nonsense' ) }
            'Using a nonsense state dies';
}

# state - ok matrix
{
    foreach my $state (qw(missing outdated current)) {
        my $e = E->new;
        my $i = Provision::DSL::Inspector->new( entity => $e, state => $state );
        
        foreach my $test_state (qw(missing outdated current)) {
            my $method = "is_$test_state";
            if ($test_state eq $state) {
                ok $i->$method, "$method is true for $test_state";
            } else {
                ok !$i->$method, "$method is false for $test_state";
            }
        }
    
        is $e->state, '', 'entity state empty';
        
        $i->inspect;
        is $e->state, $state, "entity state is set to $state";
    }
}

done_testing;
