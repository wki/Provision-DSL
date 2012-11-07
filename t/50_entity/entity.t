use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Provision::DSL::Entity';
use ok 'Provision::DSL::Inspector::Always';
use ok 'Provision::DSL::Inspector::Never';
use ok 'Provision::DSL::Installer::Debug';

{
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
    my $entity = Provision::DSL::Entity->new(
        name => 'bla', 
        inspector => ['Provision::DSL::Inspector::Always']
    );
    is $entity->state, 'outdated',
        'Always changes state to "outdated"';

    isa_ok $entity->inspector_instance, 'Provision::DSL::Inspector::Always',
        'inspector is instantiated right';

    is $entity->inspector_instance->entity, $entity,
        'inspector->entity points to entitiy';

    ok !$entity->need_privilege, 'no privilege needed';
}

# installer -- same as inspector above

# privilege
{
    # no strict 'refs';
    no warnings 'redefine';
    no warnings 'once';
    local *Provision::DSL::Inspector::Never::need_privilege = sub { 1 };

    ok +Provision::DSL::Entity->new(
        name => 'bla', 
        inspector => ['Provision::DSL::Inspector::Never']
    )->need_privilege,
        'privilege needed when inspector requests it';
}

# states/privilege/wanted depending on parent/child
{
    my @testcases = (
        # parent: s,p    child: s,p,w     expect: s,p
        [ 'missing',  0, 'current',  0,1, 'missing',  0 ],
        [ 'missing',  0, 'outdated', 0,1, 'missing',  0 ],
        [ 'missing',  0, 'missing',  0,1, 'missing',  0 ],
        [ 'missing',  0, 'current',  0,0, 'missing',  0 ],
        [ 'missing',  0, 'outdated', 0,0, 'missing',  0 ],
        [ 'missing',  0, 'missing',  0,0, 'missing',  0 ],
        
        [ 'outdated', 0, 'current',  0,1, 'outdated', 0 ],
        [ 'outdated', 0, 'outdated', 0,1, 'outdated', 0 ],
        [ 'outdated', 0, 'missing',  0,1, 'outdated', 0 ],
        [ 'outdated', 0, 'current',  0,0, 'outdated', 0 ],
        [ 'outdated', 0, 'outdated', 0,0, 'outdated', 0 ],
        [ 'outdated', 0, 'missing',  0,0, 'outdated', 0 ],
        
        [ 'current',  1, 'current',  0,1, 'current',  1 ],
        [ 'current',  0, 'outdated', 1,1, 'outdated', 1 ],
        [ 'current',  1, 'missing',  1,1, 'outdated', 1 ],
        [ 'current',  1, 'current',  0,0, 'outdated', 1 ],
        [ 'current',  0, 'outdated', 1,0, 'outdated', 1 ],
        [ 'current',  1, 'missing',  1,0, 'current',  1 ],
    );

    foreach my $testcase (@testcases) {
        my ($pstate, $ppriv,
            $cstate, $cpriv, $cwanted,
            $estate, $epriv) = @$testcase;
        my $name = join ',', @$testcase;

        my $pe = Provision::DSL::Entity->new(
            name           => 'parent',
            inspector      => [ 'Provision::DSL::Inspector::Always', {state => $pstate, need_privilege => $ppriv} ],
        );

        my $ce = Provision::DSL::Entity->new(
            name           => 'child',
            parent         => $pe,
            inspector      => [ 'Provision::DSL::Inspector::Always', {state => $cstate, need_privilege => $cpriv} ],
            wanted         => $cwanted,
        );

        $pe->add_child($ce);
        is $pe->nr_children, 1, "$name: parent has 1 child";
        is_deeply $pe->children, [$ce], "$name: child array-ref looks good";
        is_deeply [ $pe->all_children ], [$ce], "$name: child array looks good";

        is $pe->state, $estate, "$name: state is '$estate'";
        if ($epriv) {
            ok $pe->need_privilege, "$name: need privilege";
        } else {
            ok !$pe->need_privilege, "$name: do not need privilege";
        }
    }
}

# check is_ok and action depending on wanted/state
{
    my @testcases = (
        # state         wanted  is_ok  action
        [ 'missing',    0,      1,     ''],
        [ 'missing',    1,      0,     'create'],
        [ 'outdated',   0,      0,     'remove'],
        [ 'outdated',   1,      0,     'change'],
        [ 'current',    0,      0,     'remove'],
        [ 'current',    1,      1,     ''],
    );
    
    foreach my $testcase (@testcases) {
        my ($state, $wanted, $is_ok, $action) = @$testcase;
        my $name = join ',', @$testcase;
        
        my $e = Provision::DSL::Entity->new(
            name      => 'entity',
            wanted    => $wanted,
            inspector => [ 'Provision::DSL::Inspector::Always', {state => $state} ],
            installer => [ 'Provision::DSL::Installer::Debug' ],
        );

        if ($is_ok) {
            ok $e->is_ok, "$name: is ok";
        } else {
            ok !$e->is_ok, "$name: is not ok";
        }
        
        $e->install;
        is $e->installer_instance->debug_info, $action,
            "$name: called action was '$action'";
    }
}

done_testing;
