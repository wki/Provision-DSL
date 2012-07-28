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

    sub create { push @{$_[0]->_diagnostics}, 'create' }
    sub change { push @{$_[0]->_diagnostics}, 'change' }
    sub remove { push @{$_[0]->_diagnostics}, 'remove' }
}

{
    package R2;
    use Moo::Role;

    # used to fake a state from outside
    has r2_state => ( is => 'ro' );

    before state => sub {
        my $self = shift;

        $self->add_state($self->r2_state) if $self->r2_state;
    };
}

{
    package E2;
    use Moo;
    extends 'Provision::DSL::Entity';
    with 'R2';

    # used to fake a state from outside
    has e2_state => ( is => 'ro' );

    before state => sub {
        my $self = shift;

        $self->set_state($self->e2_state) if $self->e2_state;
    };
}

my $app = Provision::DSL::App->new();


# check if create, change and remove are called right
{
    my @testcases = (
        {
            name => 'missing wanted',
            attributes => {default_state => 'missing'},
            expect_before => {is_ok => 0},
            expect_after  => {_diagnostics => ['create']},
        },
        {
            name => 'missing not wanted',
            attributes => {default_state => 'missing', wanted => 0},
            expect_before => {is_ok => 1},
            expect_after  => {_diagnostics => []},
        },

        {
            name => 'outdated wanted',
            attributes => {default_state => 'outdated'},
            expect_before => {is_ok => 0},
            expect_after  => {_diagnostics => ['change']},
        },
        {
            name => 'outdated not wanted',
            attributes => {default_state => 'outdated', wanted => 0},
            expect_before => {is_ok => 0},
            expect_after  => {_diagnostics => ['remove']},
        },

        {
            name => 'current wanted',
            attributes => {default_state => 'current'},
            expect_before => {is_ok => 1},
            expect_after  => {_diagnostics => []},
        },
        {
            name => 'current not wanted',
            attributes => {default_state => 'current', wanted => 0},
            expect_before => {is_ok => 0},
            expect_after  => {_diagnostics => ['remove']},
        },

        ### TODO: add only_if, not_if test cases
        ### TODO: add "listen" test cases
    );

    foreach my $testcase (@testcases) {
        my $e = E1->new(
            app  => $app,
            name => $testcase->{name},
            %{$testcase->{attributes}},
        );

        test_expectation($e, $testcase, 'before');
        $e->execute();
        test_expectation($e, $testcase, 'after');
    }
}

# check basic state handling
{
    # default state is echoed if no other state set
    my $e1 = E1->new(
        app  => $app,
        name => 'foo',
        default_state => 'foo',
    );
    is $e1->state, 'foo', "initial state is 'default_state'";

    # using set_state, not using add_state --> set_state is kept
    foreach my $state (qw(missing outdated current)) {
        my $e1 = E1->new(
            app  => $app,
            name => 'foo',
            default_state => 'foo',
        );
        $e1->set_state($state);

        is $e1->state, $state, "set state is '$state'";
    }

    # not using set_state, only add_state --> outdated unless current
    foreach my $state (qw(missing outdated current)) {
        my $e1 = E1->new(
            app  => $app,
            name => 'foo',
            default_state => 'current',
        );
        $e1->add_state($state);

        if ($state eq 'current') {
            is $e1->state, 'current', 'only current keeps state';
        } else {
            is $e1->state, 'outdated', 'state moved to outdated';
        }
    }
    
    # using set_state and add_state --> outdate unless equal
    foreach my $set_state (qw(missing outdated current)) {
        foreach my $state (qw(missing outdated current)) {
            my $e1 = E1->new(
                app  => $app,
                name => 'foo',
                default_state => 'current',
            );
            $e1->set_state($set_state);
            $e1->add_state($state);
            
            if ($set_state eq 'missing') {
                is $e1->state, 'missing', "missing overrides '$state'";
            } elsif ($state eq $set_state) {
                is $e1->state, $state, "equal states '$state'";
            } else {
                is $e1->state, 'outdated', "different states move to 'outdated'";
            }
        }
    }
}

# check if an additional role behaves right
{
    my @testcases = (
        {
            name   => 'no states',
            states => [ undef, undef ], # e2_state and r2_state
            expect => 'current',
        },
        {
            name   => 'missing/current',
            states => [ 'missing', 'current' ],
            expect => 'missing',
        },
        {
            name   => 'current/missing',
            states => [ 'current', 'missing' ],
            expect => 'outdated',
        },
    );

    foreach my $testcase (@testcases) {
        my ($e2_state, $r2_state) = @{$testcase->{states}};

        my $e2 = E2->new(
            app  => $app,
            name => $testcase->{name},
            ($e2_state ? (e2_state => $e2_state) : ()),
            ($r2_state ? (r2_state => $r2_state) : ()),
        );

        is $e2->state, $testcase->{expect},
            "$testcase->{name}: state is '$testcase->{expect}'";
    }
}

done_testing;
