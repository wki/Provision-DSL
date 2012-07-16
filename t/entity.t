use strict;
use warnings;
use Test::More;
use Provision::DSL::App;

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
        attributes => { wanted => 0},
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
    # {
    #     name => 'not_if (1)',
    #     attributes => {not_if => sub{1}},
    #     expect => {is_present => 1, is_current => 1, state => 'current' },
    # },
    # {
    #     name => 'not_if (0)',
    #     attributes => {not_if => sub{0}},
    #     expect => {is_present => 0, is_current => 1, state => 'missing' },
    # },
    #
    # {
    #     name => 'is_ok missing',
    #     attributes => {state => 'missing'},
    #     expect => {is_ok0 => 1, is_ok1 => 0},
    # },
    # {
    #     name => 'is_ok outdated',
    #     attributes => {state => 'outdated'},
    #     expect => {is_ok0 => 0, is_ok1 => 0},
    # },
    # {
    #     name => 'is_ok current',
    #     attributes => {state => 'current'},
    #     expect => {is_ok0 => 0, is_ok1 => 1},
    # },
    #
    # {
    #     name => 'execute_1 current',
    #     attributes => {state => 'current'},
    #     execute => 'execute1',
    #     expect => {_diagnostics => []},
    # },
    # {
    #     name => 'execute_0 current',
    #     attributes => {state => 'current'},
    #     execute => 'execute0',
    #     expect => {_diagnostics => ['remove']},
    # },
    # {
    #     name => 'execute_1 outdated',
    #     attributes => {state => 'outdated'},
    #     execute => 'execute1',
    #     expect => {_diagnostics => ['change']},
    # },
    # {
    #     name => 'execute_0 outdated',
    #     attributes => {state => 'outdated'},
    #     execute => 'execute0',
    #     expect => {_diagnostics => ['remove']},
    # },
    # {
    #     name => 'execute_1 missing',
    #     attributes => {state => 'missing'},
    #     execute => 'execute1',
    #     expect => {_diagnostics => ['create']},
    # },
    # {
    #     name => 'execute_0 missing',
    #     attributes => {state => 'missing'},
    #     execute => 'execute0',
    #     expect => {_diagnostics => []},
    # },

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

    foreach my $key (sort keys(%{$testcase->{expect}})) {
        if ($testcase->{expect}->{$key} =~ m{\A [01] \z}xms) {
            if ($testcase->{expect}->{$key}) {
                ok $e->$key(),
                   "$testcase->{name}: $key is TRUE";
            } else {
                ok !$e->$key(),
                   "$testcase->{name}: $key is FALSE";
            }
        } elsif (ref $testcase->{expect}->{$key}) {
            is_deeply $e->$key(), $testcase->{expect}->{$key},
                      "$testcase->{name}: $key is as expected";
        } else {
            is $e->$key(), $testcase->{expect}->{$key},
               "$testcase->{name}: $key is $testcase->{expect}->{$key}";
        }
    }
}

done_testing;
