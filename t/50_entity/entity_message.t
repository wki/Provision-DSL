use strict;
use warnings;
use Test::More;
use Test::Output;
# use Test::Exception;
# use Path::Class;
use FindBin;

require "$FindBin::Bin/../inc/prepare_app.pl";

use ok 'Provision::DSL::Entity::Base::Message';
use ok 'Provision::DSL::Entity::Message';
use ok 'Provision::DSL::Entity::Note';
use ok 'Provision::DSL::Entity::Info';

my @testcases = (
    {
        class   => 'Message',
        name    => 'printed',
        verbose => 0,
        init    => { name => 'foobar' },
        expect  => "*** Message: foobar\n"
    },
    {
        class   => 'Message',
        name    => 'empty when not wanted',
        verbose => 0,
        init    => { name => 'foobar', wanted => 0, },
        expect  => ""
    },

    {
        class   => 'Note',
        name    => 'not printed unless verbose',
        verbose => 0,
        init    => { name => 'foobar' },
        expect  => ""
    },
    {
        class   => 'Note',
        name    => 'printed when verbose',
        verbose => 1,
        init    => { name => 'baz42' },
        expect  => "*** Note: baz42\n"
    },

    {
        class   => 'Info',
        name    => 'not printed unless verbose',
        verbose => 0,
        init    => { name => 'foobar' },
        expect  => ""
    },
    {
        class   => 'Info',
        name    => 'not printed when verbose is 1',
        verbose => 1,
        init    => { name => 'baz42' },
        expect  => ""
    },
    {
        class   => 'Info',
        name    => 'printed when verbose is 2',
        verbose => 2,
        init    => { name => 'zzz55' },
        expect  => "*** Info: zzz55\n"
    },
);

foreach my $testcase (@testcases) {
    my $class = "Provision::DSL::Entity::$testcase->{class}";
    my $m = $class->new($testcase->{init});
    
    no warnings 'redefine';
    local *Provision::DSL::App::verbose = sub { $testcase->{verbose} };
    
    stderr_is
        { $m->install }
        $testcase->{expect},
        "$testcase->{class} $testcase->{name}";
}

done_testing;
