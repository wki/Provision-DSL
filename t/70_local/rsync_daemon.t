use strict;
use warnings;
use Test::More;
use Path::Class;

use ok 'Provision::DSL::Local::RsyncDaemon';
use ok 'Provision::DSL::Local';

my $dir = Path::Class::tempdir(CLEANUP => 1);
$dir->file('foo.txt')->spew('Foo file');

my $daemon = Provision::DSL::Local::RsyncDaemon->new(dir => $dir);

ok !$daemon->has_pid, 'initially daemon does not have a pid';
ok !$daemon->is_running, 'initially daemon is not running';
ok -f $daemon->rsyncd_config_file, 'config file exists';

ok system("rsync rsync://localhost:2873/local/foo.txt $dir/bar.txt >/dev/null 2>/dev/null") >> 8,
    'rsync fails w/o daemon';

$daemon->start;
ok $daemon->has_pid, 'after start daemon has a pid';
is system("rsync rsync://localhost:2873/local/foo.txt $dir/bar.txt >/dev/null 2>/dev/null") >> 8,
    0,
    'rsync works w/ daemon';
is $dir->file('bar.txt')->slurp,
   'Foo file',
   'bar file is identical to foo file';

$daemon->stop;
ok !$daemon->has_pid, 'initially daemon does not have a pid';
ok system("rsync rsync://localhost:2873/local/foo.txt $dir/bar.txt >/dev/null 2>/dev/null") >> 8,
    'rsync fails after daemon shutdown';

done_testing;
