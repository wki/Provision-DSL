use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Provision::DSL::Entity';

# state management
{
    no strict 'refs';
    no warnings 'redefine';
    local *Provision::DSL::Types::os = sub { 'OSX' };

    is +Provision::DSL::Entity->new(name => 'bla')->state, 'current',
        'default state is "current"';
    
    is +Provision::DSL::Entity->new(name => 'bla', inspector => 'Always')->state, 
        'outdated',
        'Always changes state to "outdated"';
}


done_testing;
