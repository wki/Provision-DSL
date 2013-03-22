use strict;
use warnings;
use Test::More;

use ok 'Provision::DSL::Local::Timer';
use ok 'Provision::DSL::Local';

my $test_time = [42, 850_000]; # 42 seconds, 850 ms
no warnings 'redefine';
local *Provision::DSL::Local::Timer::gettimeofday = sub { @$test_time };
use warnings 'redefine';

my $t = Provision::DSL::Local::Timer->new;
is_deeply $t->start_time, [42,850_000], 'start time set correctly';
is $t->elapsed, 0, 'no time elapsed yet';

$test_time = [44, 350_000];
is $t->elapsed, 1.5, '1.5 s elapsed';

done_testing;
