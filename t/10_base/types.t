use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use Path::Class;

my $t_dir = dir($FindBin::Bin)->parent;

{
    package C;
    use Moo;
    use Provision::DSL::Types;
    
    has str   => (is => 'rw', isa => Str);
    has state => (is => 'rw', isa => State);
    has int   => (is => 'rw', isa => Int);
    has bool  => (is => 'rw', isa => Bool);
    has code  => (is => 'rw', isa => CodeRef);
    has efile => (is => 'rw', isa => ExistingFile);
    has bfile => (is => 'rw', isa => ExecutableFile);
    has edir  => (is => 'rw', isa => ExistingDir);
    has perl  => (is => 'rw', isa => PerlVersion);
}

my $c = C->new();

# Str, State
{
    dies_ok  { $c->str(undef) }     'undef is not a string'; 
    dies_ok  { $c->str({}) }        'hashref is not a string';
    lives_ok { $c->str('') }        'empty string is a string';
    lives_ok { $c->str('foo') }     '"foo" is a string';
    lives_ok { $c->str(42) }        '42 is a string';

    dies_ok  { $c->state(undef) }     'undef is not a state'; 
    dies_ok  { $c->state({}) }        'hashref is not a state';
    dies_ok  { $c->state('') }        'empty string is not a state';
    dies_ok  { $c->state('foo') }     '"foo" is not a state';
    foreach my $state (qw(missing outdated current)) {
        dies_ok { $c->state(uc $state) } "\U$state\E is not a state";
        dies_ok { $c->state(ucfirst $state) } "\u$state is not a state";
        dies_ok { $c->state(" $state ") } "' $state ' is not a state";
        lives_ok { $c->state($state) } "$state is a state";
    }
}

# Int, Bool
{
    dies_ok  { $c->int(undef) }     'undef is not an int'; 
    dies_ok  { $c->int({}) }        'hashref is not an int';
    dies_ok  { $c->int('') }        'empty string not an int';
    dies_ok  { $c->int('foo') }     '"foo" not an int';
    dies_ok  { $c->int(42.007) }    '42.007 not an int';
    lives_ok { $c->int(42) }        '42 is an int';

    dies_ok  { $c->bool({}) }       'hashref is not a bool';
    lives_ok { $c->bool(undef) }    'undef is a bool';
    lives_ok { $c->bool('') }       'empty string is a bool';
    lives_ok { $c->bool('foo') }    '"foo" is a bool';
    lives_ok { $c->bool(42) }       '42 is a bool';
}

# CodeRef
{
    dies_ok  { $c->code(undef) }    'undef is not a coderef'; 
    dies_ok  { $c->code({}) }       'hashref is not a bool';
    lives_ok { $c->code(sub {}) }   'a sub is a coderef';
}

# Files and Dirs
{
    dies_ok  { $c->efile('/path/to/nothing') } 'nonsense path is not existing';
    lives_ok { $c->efile("$t_dir/resources/dir1/file1.txt") } 'file1 exists';
    
    dies_ok  { $c->bfile('/path/to/nothing') } 'nonsense path is not executable';
    dies_ok  { $c->bfile("$t_dir/resources/dir1/file1.txt") } 'file1 not executable';
    lives_ok { $c->bfile("$t_dir/bin/args.sh") } 'args.sh is executable';
    
    dies_ok  { $c->edir('/path/to/nothing') } 'nonsense dir is not existing';
    lives_ok { $c->edir("$t_dir/resources/dir1") } 'dir1 exists';
}

# Perl version
{
    dies_ok { $c->perl('') } 'empty is not a perl version';
    dies_ok { $c->perl('foo') } 'foo is not a perl version';
    dies_ok { $c->perl('5.14.4') } '5.14.4 does not look like a perl version';
    lives_ok { $c->perl('perl-5.14.4') } 'perl-5.14.4 looks like a perl version';
    lives_ok { $c->perl('perl-5.14.4-RC7') } 'perl-5.14.4-RC7 looks like a perl version';
}

done_testing;
