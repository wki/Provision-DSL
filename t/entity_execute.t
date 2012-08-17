use strict;
use warnings;
use Test::More;
# use Text::Exception;
use FindBin;

my $app = require "$FindBin::Bin/inc/prepare_app.pl";

use ok 'Provision::DSL::Entity::Execute';

our $TEMPFILE = '/tmp/some_file.txt';
unlink $TEMPFILE;

my $e = Provision::DSL::Entity::Execute->new(
    app           => $app,
    name          => '/usr/bin/touch',
    default_state => 'missing',
    args          => [ $TEMPFILE ],
);

ok !-f $TEMPFILE, 'temp file not present';

$e->provision;

ok -f $TEMPFILE, 'temp file has been created';

done_testing;
