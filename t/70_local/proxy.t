use strict;
use warnings;
use Path::Class;
use Test::More;
use Test::Exception;

use ok 'Provision::DSL::Local::Proxy';
use ok 'Provision::DSL::Local';

note 'remote execution';
SKIP: {
    system 'ssh -o BatchMode=true localhost true >/dev/null 2>/dev/null';
    skip 'cannot ssh to localhost', 5
        if $? >> 8;

    system 'ssh localhost false';
    ok $? >> 8, 'false gives non-zero result status via ssh';
    
    # Provision::DSL::Local->clear_instance;
    my $proxy = Provision::DSL::Local::Proxy->new(
        host => 'localhost',
    );
    
    my $dir = Path::Class::tempdir(CLEANUP => 1);
    my $file = $dir->file('xxx.txt');

    ok !-f $file, 'touch-file does not exist';
    $proxy->run_command(touch => $file);
    ok -f $file, 'touch-file created via ssh';

    $proxy->run_command("export XX42=foo; echo \$XX42 > $file");
    is scalar $file->slurp, "foo\n", 'env export works';
}

done_testing;
