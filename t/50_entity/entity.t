use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Provision::DSL::Entity';

{
    #no strict 'refs';
    no warnings 'redefine';
    *Provision::DSL::Types::os = sub { 'OSX' };
}

# default state and default inspector
{
    is +Provision::DSL::Entity->new(name => 'bla')->state, 'current',
        'default state is "current"';
}

# provided inspector
{
    my $entity = Provision::DSL::Entity->new(name => 'bla', inspector => 'Always');
    is $entity->state, 'outdated',
        'Always changes state to "outdated"';

    is_deeply $entity->inspector, ['Provision::DSL::Inspector::Always', {}],
        'inspector class and args look good';

    isa_ok $entity->inspector_instance, 'Provision::DSL::Inspector::Always',
        'inspector is instantiated right';

    is $entity->inspector_instance->entity, $entity,
        'inspector->entity points to entitiy';

    ok !$entity->need_privilege, 'no privilege needed';
}

# privilege
{
    # no strict 'refs';
    no warnings 'redefine';
    local *Provision::DSL::Inspector::Never::need_privilege = sub { 1 };
    
    ok +Provision::DSL::Entity->new(name => 'bla')->need_privilege,
        'privilege needed when inspector requests it';
}

# states/privilege depending on parent/child
{
    my @testcases = (
        # parent        child          expect
        [ 'missing', 0, 'outdated', 0, 'missing', 0 ],
    );
    
    foreach my $testcase (@testcases) {
        my ($pstate, $ppriv,
            $cstate, $cpriv,
            $estate, $epriv) = @$testcase;
        my $name = join ',', @$testcase;
        
        my $pe = Provision::DSL::Entity->new(name => 'bla');
        my $pi = Provision::DSL::Inspector->new(entity => $pe, state => $pstate);
        $pe->inspector_instance($pi);

        my $ce = Provision::DSL::Entity->new(name => 'bla1', parent => $pe);
        my $ci = Provision::DSL::Inspector->new(entity => $ce, state => $pstate);
        $ce->inspector_instance($ci);
        
        $pe->add_child($ce);
        
        is $pe->state, $estate, "$name: state is '$estate'";
        if ($epriv) {
            ok $pe->need_privilege, "$name: need privilege";
        } else {
            ok !$pe->need_privilege, "$name: do not need privilege";
        }
    }
}

done_testing;
