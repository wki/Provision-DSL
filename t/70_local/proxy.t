use strict;
use warnings;
use Test::More;

use ok 'Provision::DSL::Local::Proxy';
use ok 'Provision::DSL::Local';

note 'command execution';
{
    # Provision::DSL::Local->clear_instance;
    my $remote = Provision::DSL::Local::Proxy->new();
}

done_testing;
