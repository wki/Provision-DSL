use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;

use ok 'Provision::DSL::Command';


my $script_dir = "$FindBin::Bin/bin";
my $c;
my $stdout;
my $stderr;


dies_ok { Provision::DSL::Command->new }
    'a command w/o name dies';


dies_ok { Provision::DSL::Command->new("$script_dir/missing.sh")->run }
    'a not existing command dies';


undef $c;
$c = Provision::DSL::Command->new("$script_dir/code42.sh");
ok $c->status < 0, 'status < 0 before execution';
dies_ok { $c->run } 'running an existing with exit status > 0 script dies';
is $c->status, 42, 'status is 42 after execution';


undef $stdout;
undef $c;
$c = Provision::DSL::Command->new("$script_dir/args.sh", 
    { 
        args => [1, 'foo'],
        stdout => \$stdout,
    });
lives_ok { $c->run } 'running an existing script lives';
is $c->status, 0, 'status is 0 after execution';
is $stdout, "args: 2 1 foo\n", 'stdout contains args';


undef $stdout;
undef $stderr;
undef $c;
$c = Provision::DSL::Command->new("$script_dir/args.sh", 
    { 
        args => [],
        stdout => \$stdout,
        stderr => \$stderr,
    });
lives_ok { $c->run } 'running an existing script lives';
is $c->status, 0, 'status is 0 after execution';
is $stdout, "args: 0 \n", 'stdout contains args';
is $stderr, "stderr\n", 'stderr is "stderr"';


undef $stdout;
undef $c;
$c = Provision::DSL::Command->new("$script_dir/env.sh", 
    { 
        args => ['bb'],
        stdout => \$stdout,
        env => { aa => 42, bb => 43, cc => 44 }
    });
lives_ok { $c->run } 'running an existing script lives';
is $stdout, "env: bb = 43\n", 'stdout contains requested env';


done_testing;
