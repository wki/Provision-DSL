use strict;
use warnings;
use Path::Class;
use Test::More;

{
    package P;
    use Moo;
    with 'Provision::DSL::Role::CommandExecution',
         'Provision::DSL::Role::ProcessControl';

}

# an existing process (this one)
{
    my $pid_file = file('/tmp/process_control.pid');
    $pid_file->spew($$);

    my $p = P->new(pid_file => $pid_file);

    ok $p->is_running, 'process reports to run';

    # allow 1 second tolerance
    ok abs($p->started - $^T) < 2, 'process start time is reported right';
}

# a non-existing process
{
    # assume that a pid will not recycle very soon.
    my $pid = `echo \$\$`;

    my $pid_file = file('/tmp/process_control.pid');
    $pid_file->spew($pid);

    my $p = P->new(pid_file => $pid_file);

    ok !$p->is_running, 'finished process reports not to run';
}

done_testing;
