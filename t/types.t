use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package C;
    use Moo;
    use Provision::DSL::Types;
    
    has str  => (is => 'rw', isa => Str);
    has bool => (is => 'rw', isa => Bool);
    has code => (is => 'rw', isa => CodeRef);
}

my $c = C->new();

# Str
{
    dies_ok  { $c->str(undef) }     'undef is not a string'; 
    dies_ok  { $c->str({}) }        'hashref is not a string';
    lives_ok { $c->str('') }        'empty string is a string';
    lives_ok { $c->str('foo') }     '"foo" is a string';
    lives_ok { $c->str(42) }        '42 is a string';
}

# Bool
{
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

done_testing;

__END__

# permission
{
    dies_ok { $c->p({}) } 'setting a hashref as a permission dies';
    dies_ok { $c->p([]) } 'setting an arrayref as a permission dies';
    
    dies_ok { $c->p('foo') } 'setting a non-octal string as a permission dies';
    dies_ok { $c->p('07') } 'setting a short octal string as a permission dies';
    
    lives_ok { $c->p('007') } 'setting an octal string lives';
    
    foreach my $perm (qw(000 001 004 007 010 040 070 111 777)) {
        lives_ok { $c->p($perm) } "setting permission to '$perm' lives";
        is oct($c->p), oct($perm), "permission '$perm' is ${\oct($perm)}";
    }
}


done_testing;
