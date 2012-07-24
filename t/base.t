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
}

my $x;


undef $x;
dies_ok { $x = X->new } 'creating a class w/o name dies';


undef $x;
$x = X->new('hello');
is $x->name, 'hello', 'name is taken from single scalar arg';
is $x->foo, 42, 'foo is default';


undef $x;
$x = X->new(bar => {foo => 'huhu'});
is $x->name, 'bar', 'name is taken from first scalar arg';
is $x->foo, 'huhu', 'foo is taken from hashref';


undef $x;
$x = X->new({name => 'baz', foo => 'zzz'});
is $x->name, 'baz', 'name is taken from hashref';
is $x->foo, 'zzz', 'foo is taken from hashref also';

done_testing;
