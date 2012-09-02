use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Provision::DSL::App';

{
    package FakeEntity;
    use Moo;
    
    has installed      => (is => 'rw', default => sub { 0 });
    has need_privilege => (is => 'rw', default => sub { 0 });
    sub install { $_[0]->installed(1) }
}

my $app = Provision::DSL::App->instance(user_has_privilege => 0);
my $e = FakeEntity->new;

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

done_testing;
