use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Provision::DSL::App::OSX';

# singleton
{
    dies_ok { Provision::DSL::App::OSX->new } 'calling new dies';
    
    my $app1 = Provision::DSL::App::OSX->instance;
    my $app2 = Provision::DSL::App::OSX->instance;
    
    is "$app1", "$app2", 'instance() repeatedly delivers same value';
}

# OS reporting
{
    my $app = Provision::DSL::App::OSX->instance;
    is $app->os, 'OSX',
        "OSX APP reports OS as 'OSX'";
}

done_testing;
