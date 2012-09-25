use strict;
use warnings;
use Test::More;
use Test::Exception;
use Provision::DSL::Entity::File;
use Provision::DSL::Entity::TestingOnly;

use ok 'Provision::DSL::App';

# singleton
{
    dies_ok { Provision::DSL::App->new } 'calling new dies';
    
    my $app1 = Provision::DSL::App->instance;
    my $app2 = Provision::DSL::App->instance;
    
    is "$app1", "$app2", 'instance() repeatedly delivers same value';
}

# OS reporting
{
    my $app = Provision::DSL::App->instance;
    is $app->os, 'Unknown',
        'base class reports OS as unknown';
}

# Privilege reporting
{
    my $app = Provision::DSL::App->instance;
    my $status = system '/usr/bin/sudo -n -u root /usr/bin/false 2>/dev/null';
    my $is_privileged = ($status >> 8) == 0;
    
    if ($is_privileged) {
        ok $app->user_has_privilege, 'user has privilege';
    } else {
        ok !$app->user_has_privilege, 'user does not have privilege';
    }
}

# creating entities
{
    my $app = Provision::DSL::App->instance;
    foreach my $class (qw(TestingOnly File)) {
        $app->entity_package_for->{$class} = "Provision::DSL::Entity::$class";
    }
    
    dies_ok { $app->create_entity(Foo => {name => 'bla', app => $app}) }
        'creating an unknown entity fails';
    
    my $e1 = $app->create_entity(TestingOnly => {name => 'bla', app => $app});
    isa_ok $e1, 'Provision::DSL::Entity::TestingOnly';
    ok exists $app->_entity_cache->{TestingOnly}->{bla}, 'TestingOnly "bla" cached';
    
    dies_ok { $app->create_entity(TestingOnly => {name => 'bla', app => $app}) }
        'creating an entity twice fails';
    
    my $e2 = $app->get_cached_entity('TestingOnly');
    is $e1, $e2, 'loading a only-one-present entity works';
    
    my $e3 = $app->create_entity(TestingOnly => {name => 'foo', app => $app});
    dies_ok { $app->get_cached_entity('TestingOnly') }
        'loading an ambigous entity dies';
    
    my $e4 = $app->get_cached_entity(TestingOnly => 'bla');
    is $e1, $e4, 'loading a properly named entity works';
}


done_testing;