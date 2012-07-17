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
    sub state { $_[0]->fake_state }
    # around state => sub {
    #     my ($orig, $self) = @_;
    #     
    #     return $self->fake_state;
    # };

    # has fake_ok => (is => 'rw', default => sub {1} );
    # 
    # around is_ok => sub {
    #     my ($orig, $self) = @_;
    #     $self->fake_ok && $self->$orig();
    # };
    
    sub create { push @{$_[0]->parent->_diagnostics}, "${\$_[0]->name}:create" }
    sub change { push @{$_[0]->parent->_diagnostics}, "${\$_[0]->name}:change" }
    sub remove { push @{$_[0]->parent->_diagnostics}, "${\$_[0]->name}:remove" }
}

{
    package C;
    use Moo;
    extends 'Provision::DSL::Entity::Compound';
    
    has fake_state => (is => 'ro', default => sub { 'current' });
    
    sub compound_state { $_[0]->fake_state }
    
    # around state => sub {
    #     my ($orig, $self) = @_;
    #     
    #     my $state = $self->fake_state;
    #     return $state || 'current' if $self->has_no_children;
    #     
    #     return $self->$orig eq $state
    #         ? $state
    #         : 'outdated';
    # };

    # has fake_ok => (is => 'rw', default => sub {1} );
    # 
    # around is_ok => sub {
    #     my ($orig, $self) = @_;
    #     $self->fake_ok && $self->$orig();
    # };
    
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
        name => 'no children, no state, wanted',
        attributes => {},
        child_states => [],
        expect_before => {state => 'current', _diagnostics => []},
        expect_after  => {_diagnostics => []},
    },
    {
        name => 'no children, no state, not wanted',
        attributes => {wanted => 0},
        child_states => [],
        expect_before => {state => 'current', _diagnostics => []},
        expect_after  => {_diagnostics => ['remove']},
    },

    {
        name => 'no children, empty state, wanted',
        attributes => {default_state => 'current'},
        child_states => [],
        expect_before => {state => 'current', _diagnostics => []},
        expect_after  => {_diagnostics => []},
    },
    {
        name => 'no children, empty state, wanted',
        attributes => {default_state => 'current', wanted => 0},
        child_states => [],
        expect_before => {state => 'current', _diagnostics => []},
        expect_after  => {_diagnostics => ['remove']},
    },
    # {
    #     name => 'missing',
    #     attributes => {fake_ok => 0},
    #     child_states => [],
    #     expect_before => {_diagnostics => []},
    #     expect_after  => {_diagnostics => ['create']},
    # },
    # {
    #     name => 'superfluous',
    #     attributes => {fake_ok => 1, wanted => 0},
    #     child_states => [],
    #     expect_before => {_diagnostics => []},
    #     expect_after  => {_diagnostics => ['remove']},
    # },
    # 
    # # 1 child
    # {
    #     name => 'missing child',
    #     attributes => {},
    #     child_states => [ {fake_ok => 0} ],
    #     expect_before => {_diagnostics => []},
    #     expect_after  => {_diagnostics => ['create', 'child_1:create']},
    # },
    # {
    #     name => 'superfluous child',
    #     attributes => {wanted => 0},
    #     child_states => [ {fake_ok => 1} ],
    #     expect_before => {_diagnostics => []},
    #     expect_after  => {_diagnostics => ['child_1:remove', 'remove']},
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
