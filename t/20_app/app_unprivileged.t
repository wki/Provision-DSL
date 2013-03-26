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

# no strict 'refs';
no warnings 'redefine';
local *Provision::DSL::App::_build_user_has_privilege = sub { 0 };
use warnings 'redefine';

my $app = Provision::DSL::App->instance();

ok !$app->user_has_privilege, 'user has no privileges';


### TODO: find more things to test

done_testing;
