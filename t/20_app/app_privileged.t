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

my $app = Provision::DSL::App->instance(user_has_privilege => 1);
my $e = FakeEntity->new;

is_deeply $app->entities_to_install, [], 'initially nothing to install';

# now this is legal.
# dies_ok { $app->install_all_entities } 'install w/o entities dies';

$app->add_entity_for_install($e);

ok !$e->installed, 'entity not marked as installed';
$app->install_all_entities;
ok $e->installed, 'entity marked as installed';

done_testing;
