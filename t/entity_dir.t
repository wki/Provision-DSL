use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Class;
use FindBin;

my $app = require "$FindBin::Bin/inc/prepare_app.pl";
my $x_dir = dir($FindBin::Bin)->absolute->resolve->subdir('x');

# creating and removing a non-existing directory
{
    clear_directory_content($x_dir);

    my $d;
    lives_ok {
        $d = Provision::DSL::Entity::Dir->new(
            name => "$FindBin::Bin/x/y",
            app => $app,
        )
    }
    'creating a named but unknown dir entity lives';

    ok !-d $d->path, 'an unknown dir does not exist';
    is $d->state, 'missing', 'an unknown dir reports state "missing"';
    ok !$d->is_ok, 'an unknown dir is not ok';

    lives_ok { $d->provision(1) } 'creating a former unknown dir lives';
    ok -d $d->path, 'a former unknown dir exists';
    is $d->state, 'current', 'an unknown dir reports state "current"';
    ok $d->is_ok, 'a former unknown dir is ok';

    lives_ok { $d->provision(0) } 'removing a dir lives';
    ok !-d $d->path, 'a removed dir does not exist';
    is $d->state, 'missing', 'a removed dir reports state "missing"';
    ok !$d->is_ok, 'a removed dir is not ok';

}

# handling an existing directory
{
    clear_directory_content($x_dir);

    my $d;
    lives_ok {
        $d = Provision::DSL::Entity::Dir->new(
            name => "$FindBin::Bin/x",
            app => $app,
        )
    }
    'creating a named and existing dir entity lives';

    ok -d $d->path, 'a known dir exists';
    is $d->state, 'current', 'a known dir reports state "current"';
    ok $d->is_ok, 'a known dir is ok';
}

# multiple dirs and copying from a resource
{
    clear_directory_content($x_dir);
    $x_dir->subdir('foo/zz')->mkpath;

    my $d;
    lives_ok {
        $d = Provision::DSL::Entity::Dir->new(
            name => "$FindBin::Bin/x/foo",
            app => $app,
            mkdir => [qw(abc def ghi/jkl)],
            rmdir => [qw(zz)],
            content => "$FindBin::Bin/resources/dir1",
        )
    }
    'creating a dir entity with structure lives';

    ok !$d->is_ok, 'dir with structure is not ok';

    # warn "BEFORE: ${\ref $_} ${\$_->name} : ${\$_->state}, OK: ${\($_->is_ok?'YES':'NO')}"
    #     for $d->all_children;

    $d->provision(1);

    # warn "AFTER: ${\ref $_} ${\$_->name} : ${\$_->state}, OK: ${\($_->is_ok?'YES':'NO')}"
    #     for $d->all_children;

    is $d->state, 'current', 'state is current after process';

    ok $d->is_ok, 'dir with structure is ok after process';

    foreach my $child (@{$d->children}) {
        ok $child->is_ok, "CHILD ${\ref $child} ${\$child->name} is OK";
    }

    ok !-d $x_dir->subdir('foo/zz'), 'unwanted directory removed';

    foreach my $dir (qw(abc def ghi ghi/jkl dir2)) {
        ok -d $d->path->subdir($dir), "subdir '$dir' ok";
    }
}

# permissions and user
SKIP: {
    skip 'need privileged user for permission tests', 6
        if !$app->user_has_privilege;

    my ($user) = grep { getpwnam $_ } qw(www-data _www)
        or skip 'no user found whose name is like "www"', 6;
    my ($uid, $gid) = (getpwnam($user))[2,3];
    my $group = getgrgid($gid);

    # diag "User $user/$group: uid=$uid, gid=$gid";

    clear_directory_content($x_dir);

    my $d;
    lives_ok {
        $d = Provision::DSL::Entity::Dir->new(
            name       => "$FindBin::Bin/x/foo",
            app        => $app,
            user       => $user,
            group      => $group,
            permission => '0640',
        )
    }
    'creating a dir entity with user and permission lives';

    ok !-d "$FindBin::Bin/x/foo", 'dir initially not present';

    $d->provision(1);

    ok -d "$FindBin::Bin/x/foo", 'dir successfully created';
    is +(stat "$FindBin::Bin/x/foo")[2] & 511, 0640, 'permission is 0640';
    is +(stat "$FindBin::Bin/x/foo")[4], $uid, "uid is $uid";
    is +(stat "$FindBin::Bin/x/foo")[5], $gid, "gid is $gid";

    $d->provision(0);

    ok !-d "$FindBin::Bin/x/foo", 'dir finally removed';
}

done_testing;

sub clear_directory_content {
    my $dir = shift;

    system "/bin/rm -rf '$dir'";
    $dir->mkpath;
}
