use strict;
use warnings;
use FindBin;
use Path::Class;
use Test::More;
use Test::Exception;

use ok 'Provision::DSL::Entity::Cron';
# use ok 'Provision::DSL::Inspector::Always';
# use ok 'Provision::DSL::Inspector::Never';

no warnings 'redefine';
local *Provision::DSL::Entity::Cron::is_root = sub { 0 };
my $x = *Provision::DSL::Entity::Cron::is_root;

my $executable = file("$FindBin::Bin/../bin/args.sh")->cleanup->resolve->stringify;

# creation of crontab line (non-root)
{
    my @testcases = (
        {
            name => 'no times given',
            args => { args => ['x'] },
            line => "* * * * * $executable x",
        },
        {
            name => 'minute',
            args => { minute => ' 1', args => ['x', 42] },
            line => "1 * * * * $executable x 42",
        },
        {
            name => 'minutes',
            args => { minute => 1, minutes => '4 ', args => ['x', 42] },
            line => "4 * * * * $executable x 42",
        },
        {
            name => 'hour',
            args => { hour => ' * / 2', args => [] },
            line => "* */2 * * * $executable",
        },
        {
            name => 'hours',
            args => { hour => 1, hours => '4,5' },
            line => "* 4,5 * * * $executable",
        },
        
        ### TODO: more.
    );
    
    foreach my $testcase (@testcases) {
        my $e = Provision::DSL::Entity::Cron->new(
            $executable, $testcase->{args}
        );
        
        is $e->crontab_line, $testcase->{line}, 
            "line: $testcase->{name}";
    }
}

# split crontab content into parts
{
    my @testcases = (
        {
            name  => 'empty',
            file  => 'f1',
            parts => [
                [],[],[],[],[]
            ],
        },
        {
            name  => 'variables only',
            file  => 'f2',
            parts => [
                [
                '# simple crontab file',
                'MAILTO = me@dojoe.com',
                ],
                [],[],[],[]
            ],
        },
        {
            name  => 'variables and rule',
            file  => 'f3',
            parts => [
                [
                    '# empty line following',
                    '',
                    'MAILTO=somebody',
                    '',
                ],
                [],[],[],
                ['0 1 2 3 4 5 /bin/crach boom bang']
            ],
        },
    );
    
    my $cron_filename;
    my %lines_for_file;
    while (my $line = <DATA>) {
        if ($line =~ m{\A --- \s* (f\d+)}xms) {
            $cron_filename = $1;
            $lines_for_file{$cron_filename} = '';
        } elsif ($cron_filename) {
            $lines_for_file{$cron_filename} .= $line;
        }
    }
    
    foreach my $testcase (@testcases) {
        my $e = Provision::DSL::Entity::Cron->new(
            $executable,
            { crontab_content => $lines_for_file{$testcase->{file}} }
        );
        
        # diag explain $e->crontab_parts;
        is_deeply $e->crontab_parts, $testcase->{parts}, 
            "parts: $testcase->{name}";
        
    }
    
    # use Data::Dumper;
    # warn Dumper \%lines_for_file
}

done_testing;

# do not remove! every part starts with --- f\d+
__DATA__
--- f1
--- f2
# simple crontab file
MAILTO = me@dojoe.com
--- f3
# empty line following

MAILTO=somebody

0 1 2 3 4 5 /bin/crach boom bang
