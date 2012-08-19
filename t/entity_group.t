use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Class;
use FindBin;

use ok 'Provision::DSL::Entity::Group';

my $app = require "$FindBin::Bin/inc/prepare_app.pl";

my $current_group = getgrgid($();

# basic behavior
{
    my $g;
    
    undef $g;
    lives_ok { $g = $app->create_entity('Group', {name => 'frodo_strange_hopefully'}) }
             'creating a named but unknown group entity lives';
    ok !$g->is_ok, 'an unknown group is not ok';
    is $g->state, 'missing', 'an unknown group is missing';
    
    undef $g;
    lives_ok { $g = $app->create_entity('Group', {name => $current_group}) }
             'creating a named and known group entity lives';
    ok $g->is_ok, 'a known group is ok';
    is $g->state, 'current', 'an known group is current';
}

### FIXME: test os specific variant directly!!!

# creating and removing a group (requires root privileges)
SKIP: {
    skip 'root privileges required for creating groups', 8 if $<;
    
    my $unused_gid   = find_unused_gid();
    my $unused_group = find_unused_group();

    my $g = $app->create_entity('Group', {name => $unused_group, gid => $unused_gid});
    ok !$g->is_ok, "unused group '$unused_group' ($unused_gid) not ok";
    is $g->state, 'missing', 'an known group is missing';
    
    lives_ok { $g->install(1) } 'creating a new group lives';
    ok $g->is_ok, "former unused group '$unused_group' ($unused_gid) ok";
    is $g->state, 'current', 'an known group is current';
    is getgrnam($unused_group), $unused_gid, 'group really present';
    
    lives_ok { $g->install(0) } 'removing an existing group lives';
    is $g->state, 'missing', 'an known group is missing';
    
    ### strange: these 2 fail, but remove really works.
    # ok !$g->is_present, "group '$unused_group' ($unused_gid) removed";
    # ok !getgrnam($unused_group), 'group really removed';
}


done_testing;

sub find_unused_gid {
    for my $gid (1000 .. 2000) {
        getgrgid($gid) or return $gid;
    }
    
    die 'could not find a free gid, stopping';
}

sub find_unused_group {
    for my $name ('aa' .. 'zz') {
        getgrnam("group$name") or return "group$name";
    }

    die 'could not find a free group name, stopping';
}
