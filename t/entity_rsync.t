use Test::More;
use Test::Exception;
use Path::Class;
use FindBin;
use Provision::DSL::App;

use ok 'Provision::DSL::Entity::Rsync';

my $x_dir = dir($FindBin::Bin)->absolute->resolve->subdir('x');
my $app = Provision::DSL::App->new();
clear_directory_content($x_dir);


my $r = Provision::DSL::Entity::Rsync->new(
    name => "$FindBin::Bin/x",
    app => $app,
    content => "$FindBin::Bin/resources/dir1",
    exclude => ['dir3'],
);
my @files = qw(file1.txt file2.txt dir2/file3.txt);

# syncing into a fresh directory
{
    ok !$r->is_current, 'not current before sync into an empty dir';
    $r->execute;
    ok $r->is_current, 'current after sync into an empty dir';
    
    ok -f $x_dir->file($_), "$_ is present"
        for @files;
}


# a changed file is discovered and updated
{
    my $fh = $x_dir->file($files[0])->openw;
    print $fh 'updated file1';
    close $fh;
    
    ok !$r->is_current, 'not current before sync into an empty dir';
    $r->execute;
    ok $r->is_current, 'current after sync into an empty dir';
    
    is scalar $x_dir->file($files[0])->slurp,
       "FILE:file1\nline2",
       'file 1 updated';
}

# a superfluous file and dir is discovered and deleted, exclude honored
{
    $x_dir->subdir('dir3')->mkpath;
    $x_dir->subdir('dir4')->mkpath;
    my $fh = $x_dir->file('file_xx.txt')->openw;
    print $fh 'superfluous file1';
    close $fh;
    
    ok !$r->is_current, 'not current before sync into an empty dir';
    $r->execute;
    ok $r->is_current, 'current after sync into an empty dir';
    
    ok !-f $x_dir->file('file_xx.txt'),
       'superfluous file deleted';
    ok -d $x_dir->subdir('dir3'),
        'excluded dir is kept';
    ok !-d $x_dir->subdir('dir4'),
        'not-excluded dir is deleted';
}

done_testing;

sub clear_directory_content {
    my $dir = shift;

    system "/bin/rm -rf '$dir'";
    $dir->mkpath;
}
