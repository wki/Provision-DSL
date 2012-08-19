use strict;
use warnings;
use Test::More;
use Test::Exception;
use Provision::DSL::Entity::File;
use Provision::DSL::Entity::TestingOnly;

use ok 'Provision::DSL::App';
use ok 'Provision::DSL::App::OSX';
use ok 'Provision::DSL::App::Ubuntu';

{
    package FakeEntity;
    use Moo;
    
    has installed       => (is => 'rw', default => sub { 0 });
    has need_privilege => (is => 'rw', default => sub { 0 });
    sub install { $_[0]->installed(1) }
}

# OS reporting
{
    my $app = Provision::DSL::App->new;
    
    is $app->os, 'Unknown', 'base class reports OS as unknown';
    foreach my $os (qw(OSX Ubuntu)) {
        my $os_app = "Provision::DSL::App::$os"->new;
        is $os_app->os, $os, "os class reports OS as '$os'";
    }
}

# Privilege reporting
{
    my $status = system '/usr/bin/sudo -n -u root /usr/bin/false 2>/dev/null';
    my $is_privileged = ($status >> 8) == 0;
    
    my $app = Provision::DSL::App->new;
    if ($is_privileged) {
        ok $app->user_has_privilege, 'user has privilege';
    } else {
        ok !$app->user_has_privilege, 'user does not have privilege';
    }
}

# install
{
    my $e = FakeEntity->new;
    
    my $app = Provision::DSL::App->new(user_has_privilege => 0);
    is_deeply $app->entities_to_install, [], 'initially nothing to install';
    
    dies_ok { $app->install_all_entities } 'install w/o entities dies';
    
    $app->add_entity_for_install($e);
    is scalar @{$app->entities_to_install}, 1, '1 entity to install';
    ok !$app->install_needs_privilege, 'no privilege needed for install';
    ok !$e->installed, 'entity not marked as installed 1';
    $app->install_all_entities;
    ok $e->installed, 'entity marked as installed 1';

    $e->need_privilege(1);
    $e->installed(0);
    ok $app->install_needs_privilege, 'privilege needed for install';
    ok !$e->installed, 'entity not marked as installed 2';
    dies_ok { $app->install_all_entities } 'install impossible w/o privileges';

    $app = Provision::DSL::App->new(user_has_privilege => 1);
    $app->add_entity_for_install($e);

    ok !$e->installed, 'entity not marked as installed 3';
    $app->install_all_entities;
    ok $e->installed, 'entity marked as installed 2';
}

# creating entities
{
    my $app = Provision::DSL::App->new;
    
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
