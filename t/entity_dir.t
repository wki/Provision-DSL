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
    ok !$d->is_present, 'an unknown dir is not present';
    
    lives_ok { $d->execute(1) } 'creating a former unknown dir lives';
    ok -d $d->path, 'a former unknown dir exists';
    ok $d->is_present, 'a former unknown dir is present';
    ok $d->is_current, 'a former unknown dir is current';
    
    lives_ok { $d->execute(0) } 'removing a dir lives';
    ok !-d $d->path, 'a removed dir does not exist';
    ok !$d->is_present, 'a removed dir is not present';
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

    ok -d $d->path,    'a known dir exists';
    ok $d->is_present, 'a known dir is present';
    ok $d->is_current, 'a known dir is current';
}

# multiple dirs and copying from a resource
{
    clear_directory_content($x_dir);
    $x_dir->subdir('zz')->mkpath;
    
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

    ok !$d->is_present, 'dir with structure is not present';
    ok !$d->is_current, 'dir with structure is not current';
    
    $d->execute(1);
    
    ok $d->is_present, 'dir with structure is present after process';
    ok $d->is_current, 'dir with structure is current after process';
    
    ok !-d $x_dir->subdir('zz'), 'unwanted directory removed';
    
    foreach my $dir (qw(abc def ghi ghi/jkl dir2)) {
        ok -d $d->path->subdir($dir), "subdir '$dir' present";
    }
}

done_testing;

sub clear_directory_content {
    my $dir = shift;

    system "/bin/rm -rf '$dir'";
    $dir->mkpath;
}
