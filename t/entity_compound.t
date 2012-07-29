use strict;
use warnings;
use FindBin;
use Test::More;
use Provision::DSL::App;

do "$FindBin::Bin/inc/entity_expectation.pl";

use ok 'Provision::DSL::Entity::Compound';

{
    package E;
    use Moo;
    extends 'Provision::DSL::Entity';
    
    has fake_state => (is => 'rw', default => sub { 'current' });
    before state => sub { $_[0]->set_state($_[0]->fake_state) };
    
    sub create { push @{$_[0]->parent->_diagnostics}, "${\$_[0]->name}:create" }
    sub change { push @{$_[0]->parent->_diagnostics}, "${\$_[0]->name}:change" }
    sub remove { push @{$_[0]->parent->_diagnostics}, "${\$_[0]->name}:remove" }
}

{
    package C;
    use Moo;
    extends 'Provision::DSL::Entity::Compound';
    
    has fake_state => (is => 'rw', default => sub { 'current' });
    before state => sub { $_[0]->set_state($_[0]->fake_state) };
    
    has _diagnostics => (
        is => 'rw',
        default => sub { [] },
    );
    
    # times are reversed here to see time of firing
    before create => sub { push @{$_[0]->_diagnostics}, 'create' };
    before change => sub { push @{$_[0]->_diagnostics}, 'change' };
    after  remove => sub { push @{$_[0]->_diagnostics}, 'remove' };
}

my @testcases = (
    
    # no children
    {
        name => 'no children, current state, wanted',
        attributes => {fake_state => 'current'},
        child_states => [],
        expect_before => {state => 'current', _diagnostics => []},
        expect_after  => {_diagnostics => []},
    },
    {
        name => 'no children, current state, not wanted',
        attributes => {fake_state => 'current', wanted => 0},
        child_states => [],
        expect_before => {state => 'current', _diagnostics => []},
        expect_after  => {_diagnostics => ['remove']},
    },

    {
        name => 'no children, outdated state, wanted',
        attributes => {fake_state => 'outdated'},
        child_states => [],
        expect_before => {state => 'outdated', _diagnostics => []},
        expect_after  => {_diagnostics => ['change']},
    },
    {
        name => 'no children, outdated state, not wanted',
        attributes => {fake_state => 'outdated', wanted => 0},
        child_states => [],
        expect_before => {state => 'outdated', _diagnostics => []},
        expect_after  => {_diagnostics => ['remove']},
    },

    {
        name => 'no children, missing state, wanted',
        attributes => {fake_state => 'missing'},
        child_states => [],
        expect_before => {state => 'missing', _diagnostics => []},
        expect_after  => {_diagnostics => ['create']},
    },
    {
        name => 'no children, missing state, not wanted',
        attributes => {fake_state => 'missing', wanted => 0},
        child_states => [],
        expect_before => {state => 'missing', _diagnostics => []},
        expect_after  => {_diagnostics => []},
    },

    # 1 child
    {
        name => 'current parent / current child',
        attributes => {fake_state => 'current'},
        child_states => [ {fake_state => 'current'} ],
        expect_before => {state => 'current', _diagnostics => []},
        expect_after  => {state => 'current', _diagnostics => []},
    },
    {
        name => 'current parent / missing child',
        attributes => {fake_state => 'current'},
        child_states => [ {fake_state => 'missing'} ],
        expect_before => {state => 'outdated', _diagnostics => []},
        expect_after  => {_diagnostics => ['change', 'child_1:create']},
    },
);

foreach my $testcase (@testcases) {
    my $app = Provision::DSL::App->new();
    
    my $c = C->new({app => $app, name => $testcase->{name}, %{$testcase->{attributes}}});
    my $i = 1;
    for my $state (@{$testcase->{child_states}}) {
        $c->add_child(E->new({app => $app, name => "child_${\$i++}", parent => $c, %$state}));
    }
    
    test_expectation($c, $testcase, 'before');
    $c->execute;
    test_expectation($c, $testcase, 'after');
}


done_testing;
