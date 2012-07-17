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
        # isa => 'ArrayRef',
        default => sub { [] },
    );

    has fake_ok => (is => 'rw', default => sub {1} );

    around is_ok => sub {
        my ($orig, $self) = @_;
        $self->fake_ok && $self->$orig();
    };

    sub execute0 { $_[0]->execute(0) }
    sub execute1 { $_[0]->execute(1) }

    sub create { push @{$_[0]->_diagnostics}, 'create' }
    sub remove { push @{$_[0]->_diagnostics}, 'remove' }
}

my @testcases = (
    {
        name => 'no attributes',
        attributes => {},
        expect => {is_ok => 1},
    },
    {
        name => 'not wanted',
        attributes => {wanted => 0},
        expect => {is_ok => 1},
    },
    {
        name => 'no attributes, fake_ok 0',
        attributes => {fake_ok => 0},
        expect => {is_ok => 0},
    },
    {
        name => 'not wanted, fake_ok 0',
        attributes => {wanted => 0},
        expect => {is_ok => 1},
    },
    {
        name => 'only_if (1)',
        attributes => {only_if => sub{1}},
        expect => {is_ok => 0},
    },
    {
        name => 'only_if (0)',
        attributes => {only_if => sub{0}},
        expect => {is_ok => 1},
    },
    {
        name => 'not_if (1)',
        attributes => {not_if => sub{1}},
        expect => {is_ok => 1},
    },
    {
        name => 'not_if (0)',
        attributes => {not_if => sub{0}},
        expect => {is_ok => 0},
    },
    
    {
        name => 'execute 0 -> wanted',
        attributes => {fake_ok => 0, wanted => 1},
        execute => 'execute',
        expect => {_diagnostics => ['create']},
    },
    {
        name => 'execute 1 -> wanted',
        attributes => {fake_ok => 1, wanted => 1},
        execute => 'execute',
        expect => {_diagnostics => []},
    },
    {
        name => 'execute 0 -> not wanted',
        attributes => {fake_ok => 0, wanted => 0},
        execute => 'execute',
        expect => {_diagnostics => []},
    },
    {
        name => 'execute 1 -> not wanted',
        attributes => {fake_ok => 1, wanted => 0},
        execute => 'execute',
        expect => {_diagnostics => ['remove']},
    },
    
    {
        name => 'execute0 0 -> wanted',
        attributes => {fake_ok => 0, wanted => 1},
        execute => 'execute0',
        expect => {_diagnostics => []},
    },
    {
        name => 'execute0 1 -> wanted',
        attributes => {fake_ok => 1, wanted => 1},
        execute => 'execute0',
        expect => {_diagnostics => ['remove']},
    },
    {
        name => 'execute0 0 -> not wanted',
        attributes => {fake_ok => 0, wanted => 0},
        execute => 'execute0',
        expect => {_diagnostics => []},
    },
    {
        name => 'execute0 1 -> not wanted',
        attributes => {fake_ok => 1, wanted => 0},
        execute => 'execute0',
        expect => {_diagnostics => ['remove']},
    },

    {
        name => 'execute1 0 -> wanted',
        attributes => {fake_ok => 0, wanted => 1},
        execute => 'execute1',
        expect => {_diagnostics => ['create']},
    },
    {
        name => 'execute1 1 -> wanted',
        attributes => {fake_ok => 1, wanted => 1},
        execute => 'execute1',
        expect => {_diagnostics => []},
    },
    {
        name => 'execute1 0 -> not wanted',
        attributes => {fake_ok => 0, wanted => 0},
        execute => 'execute1',
        expect => {_diagnostics => ['create']},
    },
    {
        name => 'execute1 1 -> not wanted',
        attributes => {fake_ok => 1, wanted => 0},
        execute => 'execute1',
        expect => {_diagnostics => []},
    },

    ### TODO: add "listen" test cases
);

my $app = Provision::DSL::App->new();

foreach my $testcase (@testcases) {
    my $e = E1->new(
        app => $app,
        name =>$testcase->{name},
        %{$testcase->{attributes}},
    );

    if (exists $testcase->{execute}) {
        my $method = $testcase->{execute};
        $e->$method();
    }
    
    test_expectation($e, $testcase);
}

done_testing;
