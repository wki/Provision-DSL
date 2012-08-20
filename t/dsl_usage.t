use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Provision::DSL';


TestingOnly 'aaaa';
is TestingOnly('aaaa')->name, 'aaaa', 'aaaa: name is taken from creation';
is TestingOnly('aaaa')->foo,  'aaaa', 'aaaa: foo is taken from name';
ok !TestingOnly('aaaa')->has_bar, 'aaaa: no bar';
ok !TestingOnly('aaaa')->has_baz, 'aaaa: no baz';


Defaults {
    Foo => { bar => 123 },
    TestingOnly => { bar => 42 },
};

TestingOnly 'bbbb';
is TestingOnly('bbbb')->name, 'bbbb', 'bbbb: name is taken from creation';
is TestingOnly('bbbb')->foo,  'bbbb', 'bbbb: foo is taken from name';
is TestingOnly('bbbb')->bar, 42, 'bbbb: bar taken from default';
ok !TestingOnly('bbbb')->has_baz, 'bbbb: no baz';


Defaults {
    TestingOnly => { bar => 'a', baz => 'b' },
};

TestingOnly 'cccc' => { bar => 'zz' };
is TestingOnly('cccc')->name, 'cccc', 'cccc: name is taken from creation';
is TestingOnly('cccc')->foo,  'cccc', 'cccc: foo is taken from name';
is TestingOnly('cccc')->bar, 'zz', 'cccc: bar taken from creation';
is TestingOnly('cccc')->baz, 'b', 'cccc: baz taken from default';

# prevent error message in Provision::DSL::END{} from firing
Provision::DSL::App->instance->is_running(1);

done_testing;
