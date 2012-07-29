use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Class;
use FindBin;
use Provision::DSL::App;

use ok 'Provision::DSL::Entity::File';

my $x_dir = dir($FindBin::Bin)->absolute->resolve->subdir('x');

use ok 'Provision::DSL::Entity::User';
use ok 'Provision::DSL::Entity::Group';

my $x_dir = dir($FindBin::Bin)->absolute->resolve->subdir('x');
my $app = Provision::DSL::App->new(
    entity_package_for => {
        User  => 'Provision::DSL::Entity::User',
        Group => 'Provision::DSL::Entity::Group',
    },
);

{
    package Provision::DSL;

    no strict 'refs';
    $Provision::DSL::app = $app;
}




# unknown file
{
    clear_directory_content($x_dir);

    my $f;
    lives_ok { 
        $f = Provision::DSL::Entity::File->new(
            app => $app,
            name => "$FindBin::Bin/x/file.ext", 
            content => 'foo'
        )
    }
    'creating an unknown file entity lives';
    
    ok !-f $f->path, 'an unknown file does not exist';
    ok !$f->is_ok, 'an unknown file is not ok';
    
    lives_ok { $f->execute(1) } 'creating a former unknown file lives';
    ok -f $f->path, 'a former unknown file exists';
    ok $f->is_ok, 'a former unknown file is ok';
    is $f->state, 'current', 'former unknown file is in current state';
    
    is scalar $f->path->slurp, 'foo', 'content is "foo"';
    
    lives_ok { $f->execute(0) } 'removing a file lives';
    ok !-f $f->path, 'a removed file does not exist';
    ok !$f->is_ok, 'a removed file is not ok';
}

# known file
{
    my $f;
    lives_ok { 
        $f = Provision::DSL::Entity::File->new(
            app => $app,
            name => "$FindBin::Bin/x/file.ext", 
            content => 'foo'
        )
    }
    'creating a known file lives';
    
    lives_ok { $f->execute(1) } 'creating a file from a resource lives';
    is scalar $f->path->slurp, 'foo',
       'file content matches requirement';

    my $fh = scalar $f->path->openw;
    print $fh 'something different';
    close $fh;
}

# file from resource
{
    my $f;
    lives_ok { 
        $f = Provision::DSL::Entity::File->new(
            app => $app,
            name => "$FindBin::Bin/x/file.ext", 
            content => file("$FindBin::Bin/resources/dir1/file1.txt"),
        )
    }
    'creating a file with a resource content lives';
    
    ok scalar $f->path->slurp ne "FILE:file1\nline2",
       'file content is different from resource';
    ok !$f->is_ok, 'file is reported as not ok';
    lives_ok { $f->execute(1) } 'updating a file from a resource lives';
    is scalar $f->path->slurp, "FILE:file1\nline2",
       'file content matches resource file';
}

done_testing;

sub clear_directory_content {
    my $dir = shift;

    system "/bin/rm -rf '$dir'";
    $dir->mkpath;
}
