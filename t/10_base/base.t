use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Provision::DSL::Base';

{
    package X;
    use Moo;
    extends 'Provision::DSL::Base';

    has foo => (
        is => 'ro',
        default => sub { 42 },
    );

    has boo => (
        is => 'ro',
        default => sub { 42 },
    );

    has noo => (
        is => 'ro',
        default => sub { 42 },
    );
}

my $x;


undef $x;
dies_ok { $x = X->new } 'creating a class w/o name dies';


# name from first arg if scalar
undef $x;
$x = X->new('hello');
is $x->name, 'hello', 'name is taken from single scalar arg';
is $x->foo, 42, 'foo is default';


# second arg hashref
undef $x;
$x = X->new(bar => {foo => 'huhu'});
is $x->name, 'bar', 'name is taken from first scalar arg';
is $x->foo, 'huhu', 'foo is taken from hashref';


# additional list after hashref
undef $x;
$x = X->new(bar => {foo => 'huhu'}, boo => 22);
is $x->name, 'bar', 'name is taken from first scalar arg';
is $x->foo, 'huhu', 'foo is taken from hashref';
is $x->boo, 22, 'boo is taken from list after hashref';


# hashref for everything
undef $x;
$x = X->new({name => 'baz', foo => 'zzz'});
is $x->name, 'baz', 'name is taken from hashref';
is $x->foo, 'zzz', 'foo is taken from hashref also';


done_testing;
