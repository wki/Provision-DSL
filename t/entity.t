use strict;
use warnings;
use FindBin;
use Test::More;
use Provision::DSL::App;

do "$FindBin::Bin/inc/entity_expectation.pl";

use ok 'Provision::DSL::Entity';

{
    package E1;
    use Moo;
    extends 'Provision::DSL::Entity';

    has _diagnostics => (
        is => 'rw',
        default => sub { [] },
    );
    
    has fake_state => (is => 'rw', default => sub { 'current' });
    sub state { $_[0]->fake_state }

    sub create { push @{$_[0]->_diagnostics}, 'create' }
    sub change { push @{$_[0]->_diagnostics}, 'change' }
    sub remove { push @{$_[0]->_diagnostics}, 'remove' }
}

my @testcases = (
    {
        name => 'missing wanted',
        attributes => {fake_state => 'missing'},
        expect_before => {is_ok => 0},
        expect_after  => {_diagnostics => ['create']},
    },
    {
        name => 'missing not wanted',
        attributes => {fake_state => 'missing', wanted => 0},
        expect_before => {is_ok => 1},
        expect_after  => {_diagnostics => []},
    },
    
    {
        name => 'outdated wanted',
        attributes => {fake_state => 'outdated'},
        expect_before => {is_ok => 0},
        expect_after  => {_diagnostics => ['change']},
    },
    {
        name => 'outdated not wanted',
        attributes => {fake_state => 'outdated', wanted => 0},
        expect_before => {is_ok => 0},
        expect_after  => {_diagnostics => ['remove']},
    },
    
    {
        name => 'current wanted',
        attributes => {fake_state => 'current'},
        expect_before => {is_ok => 1},
        expect_after  => {_diagnostics => []},
    },
    {
        name => 'current not wanted',
        attributes => {fake_state => 'current', wanted => 0},
        expect_before => {is_ok => 0},
        expect_after  => {_diagnostics => ['remove']},
    },
    
    ### TODO: add only_if, not_if test cases
    ### TODO: add "listen" test cases
);

my $app = Provision::DSL::App->new();

foreach my $testcase (@testcases) {
    my $e = E1->new(
        app => $app,
        name =>$testcase->{name},
        %{$testcase->{attributes}},
    );

    test_expectation($e, $testcase, 'before');
    $e->execute();
    test_expectation($e, $testcase, 'after');
}

done_testing;
