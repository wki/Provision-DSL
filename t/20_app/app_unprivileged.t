use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Provision::DSL::App';

no warnings 'redefine';
local *Provision::DSL::App::_try_to_modify_sudoers = sub {};

{
    package FakeEntity;
    use Moo;
    
    has installed      => (is => 'rw', default => sub { 0 });
    has need_privilege => (is => 'rw', default => sub { 0 });
    sub install { $_[0]->installed(1) }
}

no strict 'refs';
no warnings 'redefine';
local *Provision::DSL::App::_build_user_has_privilege = sub { 0 };

my $app = Provision::DSL::App->instance();
my $e = FakeEntity->new;

ok !$app->user_has_privilege, 'user has no privileges';

is_deeply $app->entities_to_install, [], 'initially nothing to install';

# now this is legal
# dies_ok { $app->install_all_entities } 'install w/o entities dies';

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
ok !$e->installed, 'entity still not marked as installed';

done_testing;
