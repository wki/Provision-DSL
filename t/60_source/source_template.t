use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;

use ok 'Provision::DSL::Source::Template';

my $root_dir = "$FindBin::Bin/../resources";

my $t = Provision::DSL::Source::Template->new(
    { 
        root_dir => $root_dir, 
        name => 'dirx/file.tt', 
        vars => { var1 => 42 },
    }
);

is $t->content,
    "template 42 done\n\ninclude done\n",
    'template rendered right';

done_testing;
