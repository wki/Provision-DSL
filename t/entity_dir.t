use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Class;
use FindBin;
use Provision::DSL::App;

use ok 'Provision::DSL::Entity::Dir';
use ok 'Provision::DSL::Entity::Rsync';

my $x_dir = dir($FindBin::Bin)->absolute->resolve->subdir('x');
my $app = Provision::DSL::App->new(
    entity_package_for => {
        Dir   => 'Provision::DSL::Entity::Dir',
        Rsync => 'Provision::DSL::Entity::Rsync',
    },
);

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
    ok !$d->is_ok, 'an unknown dir is not ok';
    
    lives_ok { $d->execute(1) } 'creating a former unknown dir lives';
    ok -d $d->path, 'a former unknown dir exists';
    ok $d->is_ok, 'a former unknown dir is ok';
    
    lives_ok { $d->execute(0) } 'removing a dir lives';
    ok !-d $d->path, 'a removed dir does not exist';
    ok !$d->is_ok, 'a removed dir is not ok';
}

# creating an existing directory
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
    
    $d->execute(1);
    
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

done_testing;

sub clear_directory_content {
    my $dir = shift;

    system "/bin/rm -rf '$dir'";
    $dir->mkpath;
}
