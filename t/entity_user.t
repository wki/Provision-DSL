use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Class;
use FindBin;
use Provision::DSL::App;

use ok 'Provision::DSL::Entity::User';

my $app = require "$FindBin::Bin/inc/prepare_app.pl";

my $current_user = getpwuid($<);

# basic behavior
{
    my $u;
    
    undef $u;
    lives_ok { $u = $app->create_entity('User', {name => 'frodo_unknown_hopefully' }) }
             'creating a named but unknown user entity lives';
    ok !$u->is_ok, 'an unknown user is not ok';
    is $u->state, 'missing', 'an unknown user is missing';
    
    
    undef $u;
    lives_ok { $u = $app->create_entity('User', {name => $current_user }) }
             'creating a named and known user entity lives';
    ok $u->is_ok, 'a known user is ok';
    is $u->state, 'current', 'a known user is current';
    isa_ok $u->home_dir, 'Path::Class::Dir';
    ok -d $u->home_dir, 'home directory exists';
    # fails for root when started via sudo
    # is $u->home_dir->absolute->resolve->stringify,
    #    dir($ENV{HOME})->absolute->resolve->stringify,
    #    'home directory eq $ENV{HOME}';
    isa_ok $u->group, 'Provision::DSL::Entity::Group';
}

# creating and removing a user (requires root privileges)
SKIP: {
    skip 'root privileges required for creating users', 9 if $<;
    
    my $unused_uid  = find_unused_uid();
    my $unused_user = find_unused_user();
    my $group       = find_a_group();
    
    # warn "USING GROUP: $group";
    # my $g = Group($group);

    my $u = $app->create_entity('User', {name => $unused_user, uid => $unused_uid, group => $group});
    ok !$u->is_present, "unused user '$unused_user' ($unused_uid) not present";
    
    lives_ok { $u->execute(1) } 'creating a new user lives';
    ok $u->is_ok, "former unused user '$unused_user' ($unused_uid) present";
    is $u->state, 'current', 'a created user is current';
    is getpwnam($unused_user), $unused_uid, 'user really present';
    
    lives_ok { $u->execute(0) } 'removing an existing user lives';
    
    ### strange: these 2 fail, but remove really works.
    ok !$u->is_ok, "user '$unused_user' ($unused_uid) removed";
    is $u->state, 'missing', 'an unknown user is missing';
    ok !getpwnam($unused_user), 'user really removed';
}


done_testing;


sub find_a_group {
    for my $gid (1 .. 1000) {
        my $name = getgrgid($gid);
        return $name if defined $name;
    }
    
    die 'could not find a group';
}

sub find_unused_uid {
    for my $uid (1000 .. 2000) {
        getpwuid($uid) or return $uid;
    }
    
    die 'could not find a free uid, stopping';
}

sub find_unused_user {
    for my $name ('aa' .. 'zz') {
        getpwnam("user$name") or return "user$name";
    }

    die 'could not find a free user name, stopping';
}

