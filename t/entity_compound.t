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
    
    has fake_ok => (is => 'rw', default => sub {1} );

    around is_ok => sub {
        my ($orig, $self) = @_;
        $self->fake_ok && $self->$orig();
    };
    
    sub create { push @{$_[0]->parent->_diagnostics}, "${\$_[0]->name}:create" }
    sub remove { push @{$_[0]->parent->_diagnostics}, "${\$_[0]->name}:remove" }
}

{
    package C;
    use Moo;
    extends 'Provision::DSL::Entity::Compound';
    
    has fake_ok => (is => 'rw', default => sub {1} );

    around is_ok => sub {
        my ($orig, $self) = @_;
        $self->fake_ok && $self->$orig();
    };
    
    has _diagnostics => (
        is => 'rw',
        default => sub { [] },
    );
    
    after create => sub { push @{$_[0]->_diagnostics}, 'create' };
    after remove => sub { push @{$_[0]->_diagnostics}, 'remove' };
}

my @testcases = (
    
    # no children
    {
        name => 'empty',
        attributes => {},
        child_states => [],
        expect_before => {_diagnostics => []},
        expect_after  => {_diagnostics => []},
    },
    {
        name => 'missing',
        attributes => {fake_ok => 0},
        child_states => [],
        expect_before => {_diagnostics => []},
        expect_after  => {_diagnostics => ['create']},
    },
    {
        name => 'superfluous',
        attributes => {fake_ok => 1, wanted => 0},
        child_states => [],
        expect_before => {_diagnostics => []},
        expect_after  => {_diagnostics => ['remove']},
    },

    # {
    #     name => 'missing',
    #     attributes => {fake_ok => 0},
    #     child_states => [],
    #     execute_arg => 1,
    #     expect => {is_ok => 0},
    #     diagnostics => ['create'],
    # },
    
    # # 1 child
    # {
    #     name => 'missing->1',
    #     child_states => [ {is_present => 0, is_current => 1} ],
    #     execute_arg => 1,
    #     expect => {state => 'missing', is_present => 0, is_current => 1},
    #     diagnostics => ['create', 'child_1:create'],
    # },
    # {
    #     name => 'missing->0',
    #     child_states => [ {is_present => 0, is_current => 1} ],
    #     execute_arg => 0,
    #     expect => {state => 'missing', is_present => 0, is_current => 1},
    #     diagnostics => [],
    # },
    # {
    #     name => 'outdated->1',
    #     child_states => [ {is_present => 1, is_current => 0} ],
    #     execute_arg => 1,
    #     expect => {state => 'outdated', is_present => 1, is_current => 0},
    #     diagnostics => ['change', 'child_1:change'],
    # },
    # {
    #     name => 'outdated->0',
    #     child_states => [ {is_present => 1, is_current => 0} ],
    #     execute_arg => 0,
    #     expect => {state => 'outdated', is_present => 1, is_current => 0},
    #     diagnostics => ['child_1:remove', 'remove'],
    # },
    # {
    #     name => 'current->1',
    #     child_states => [ {is_present => 1, is_current => 1} ],
    #     execute_arg => 1,
    #     expect => {state => 'current', is_present => 1, is_current => 1},
    #     diagnostics => [],
    # },
    # {
    #     name => 'current->0',
    #     child_states => [ {is_present => 1, is_current => 1} ],
    #     execute_arg => 0,
    #     expect => {state => 'current', is_present => 1, is_current => 1},
    #     diagnostics => ['child_1:remove', 'remove'],
    # },
    # 
    # # 2 children
    # {
    #     name => 'missing,outdated->1',
    #     child_states => [ {is_present => 0, is_current => 1}, {is_present => 1, is_current => 0} ],
    #     execute_arg => 1,
    #     expect => {state => 'outdated', is_present => 1, is_current => 0},
    #     diagnostics => ['change', 'child_1:create', 'child_2:change'],
    # },
    # {
    #     name => 'missing,outdated->0',
    #     child_states => [ {is_present => 0, is_current => 1}, {is_present => 1, is_current => 0} ],
    #     execute_arg => 0,
    #     expect => {state => 'outdated', is_present => 1, is_current => 0},
    #     diagnostics => ['child_2:remove', 'remove'],
    # },
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
