use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Provision::DSL::App::Ubuntu';

# singleton
{
    dies_ok { Provision::DSL::App::Ubuntu->new } 'calling new dies';
    
    my $app1 = Provision::DSL::App::Ubuntu->instance;
    my $app2 = Provision::DSL::App::Ubuntu->instance;
    
    is "$app1", "$app2", 'instance() repeatedly delivers same value';
}

# OS reporting
{
    my $app = Provision::DSL::App::Ubuntu->instance;
    is $app->os, 'Ubuntu',
        "Ubuntu APP reports OS as 'Ubuntu'";
}

done_testing;
