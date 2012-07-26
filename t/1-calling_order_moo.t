use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib_moo";
use ok 'ParentX';
use ok 'ParentT';
use ok 'Child';
use ok 'ModifyingChild';

# we need: Role-Tiny 1.001003, Moo 0.091011
# versions before bahave differently

#
# without inheritance,
# method, class-modifiers and role-mofifiers are called
#
my $p = ParentX->new;
$p->method();

is join(" / ", @{$p->message}),
   'before P::m / b PR2::m / b PR1::m / before PR2::m / before PR1::m / '
 . 'in P::m / '
 . 'after PR1::m / after PR2::m / a PR1::m / a PR2::m / after P::m',
   'parent calling order is OK';


#
# with inheritance and overwriting method
# ONLY CHILD METHOD AND MODIFIERS ARE CALLED, PARENT IS IGNORED
#
my $c = Child->new;
$c->method();

is join(" / ", @{$c->message}),
   'before C::m / b CR2::m / b CR1::m / before CR2::m / before CR1::m / ' # parent missing
 . 'in C::m / '
 . 'after CR1::m / after CR2::m / a CR1::m / a CR2::m / after C::m',      # parent missing
   'child calling order is OK';


#
# only using modifiers behaves AS EXPECTED
#
my $m = ModifyingChild->new;
$m->method();

is join(" / ", @{$m->message}),
   'b MC::m / b CR2::m / b CR1::m / before MC::m / before CR2::m / before CR1::m / '
 . 'before P::m / b PR2::m / b PR1::m / before PR2::m / before PR1::m / '
 . 'in P::m / '
 . 'after PR1::m / after PR2::m / a PR1::m / a PR2::m / after P::m / '
 . 'after CR1::m / after CR2::m / after MC::m / a CR1::m / a CR2::m / a MC::m',
   'modifying child calling order is OK';


#
# using traits does not affect classes
#
my $m1 = ParentT->new;
$m1->method();
is join(" / ", @{$m1->message}),
   'before P::m / in P::m / after P::m',
   'no-trait calling order is OK';

my $m2 = ParentT->new;
Role::Tiny->apply_roles_to_object($m2, 'Trait');
$m2->method();

is join(" / ", @{$m2->message}),
   'b T::m / before T::m / before P::m / '
 . 'in P::m / '
 . 'after P::m / after T::m / a T::m',
   'trait calling order is OK';

my $m3 = ParentT->new;
$m3->method();
is join(" / ", @{$m3->message}),
   'before P::m / in P::m / after P::m',
   'no-trait calling order is still OK';


done_testing;
