use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Class;
use FindBin;

use ok 'Provision::DSL::Entity::Rsync';

my $x_dir = dir($FindBin::Bin)->absolute->resolve->subdir('x');

clear_directory_content($x_dir);

my @files = qw(file1.txt file2.txt dir2/file3.txt);

# syncing into a fresh directory
{
    my $r = new_rsync();

    is $r->state, 'outdated', 'outdated before sync into an empty dir';
    $r->install;
    is $r->state, 'current', 'current after sync into an empty dir';
    
    ok -f $x_dir->file($_), "$_ is present"
        for @files;
}


# a changed file is discovered and updated
{
    my $r = new_rsync();
    
    my $fh = $x_dir->file($files[0])->openw;
    print $fh 'updated file1';
    close $fh;
    
    is $r->state, 'outdated', 'not ok before sync into a changed dir 1';
    $r->install;
    is $r->state, 'current', 'current after sync into a changed dir 1';
    
    is scalar $x_dir->file($files[0])->slurp,
       "FILE:file1\nline2",
       'file 1 updated';
}

# a superfluous file and dir is discovered and deleted, exclude honored
{
    my $r = new_rsync();
    
    $x_dir->subdir('dir3')->mkpath;
    $x_dir->subdir('dir4')->mkpath;
    my $fh = $x_dir->file('file_xx.txt')->openw;
    print $fh 'superfluous file1';
    close $fh;
    
    is $r->state, 'outdated', 'outdated before sync into a changed dir 2';
    $r->install;
    is $r->state, 'current', 'current after sync into a changed dir 2';
    
    ok !-f $x_dir->file('file_xx.txt'),
       'superfluous file deleted';
    ok -d $x_dir->subdir('dir3'),
        'excluded dir is kept';
    ok !-d $x_dir->subdir('dir4'),
        'not-excluded dir is deleted';
}

done_testing;

sub new_rsync {
    Provision::DSL::Entity::Rsync->new(
        name => "$FindBin::Bin/x",
        content => "$FindBin::Bin/resources/dir1",
        exclude => ['dir3'],
    );
}

sub clear_directory_content {
    my $dir = shift;

    system "/bin/rm -rf '$dir'";
    $dir->mkpath;
}
