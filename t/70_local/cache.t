use strict;
use warnings;
use Test::More;
use Path::Class;
use Provision::DSL::Const;
use FindBin;

use ok 'Provision::DSL::Local::Cache';
use ok 'Provision::DSL::Local';

note 'subdir creation';
{
    Provision::DSL::Local->clear_instance;
    my $dir = Path::Class::tempdir(CLEANUP => 1);
    is join('|', sort map {$_->basename} $dir->children),
       '',
       'no subdirs present';
    
    my $cache = Provision::DSL::Local::Cache->new(dir => $dir);
    is join('|', sort map {$_->basename} $dir->children),
       'bin|lib|log|resources',
       '4 subdirs created';
}

note 'perlbrew installer';
{
    Provision::DSL::Local->clear_instance;

    no warnings 'redefine';
    local *Provision::DSL::Script::Provision::http_get =
        sub { $_[1] };
    use warnings 'redefine';

    my $dir       = Path::Class::tempdir(CLEANUP => 1);
    my $cache     = Provision::DSL::Local::Cache->new(dir => $dir);
    my $installer = $dir->file(PERLBREW_INSTALLER);
    
    ok !-f $installer, 'perlbrew installer missing';
    $cache->pack_perlbrew_installer;
    ok -f $installer, 'perlbrew installer loaded';
}

note 'dependencies';
{
    Provision::DSL::Local->clear_instance;
    my $dir     = Path::Class::tempdir(CLEANUP => 1);
    my $cache   = Provision::DSL::Local::Cache->new(dir => $dir);
    my $lib_dir = $dir->subdir('lib/perl5');
    
    $cache->config->local->{cpanm} = "$FindBin::Bin/../bin/fake_cpanm.pl";
    
    ok !-d $lib_dir, 'lib dir not present before deps';
    $cache->pack_dependent_libs;
    ok -d $lib_dir, 'lib dir present after install deps';
    ok scalar $lib_dir->children > 10, 'libs installed';
}

note 'provision_libs';
{
    Provision::DSL::Local->clear_instance;
    my $dir     = Path::Class::tempdir(CLEANUP => 1);
    my $cache   = Provision::DSL::Local::Cache->new(dir => $dir);
    my $lib_dir = $dir->subdir('lib/perl5');
    
    ok !-d $lib_dir, 'lib dir not present before pack provision';
    $cache->pack_provision_libs;
    ok -d $lib_dir, 'lib dir present after pack provision';
    ok -d $lib_dir->subdir('Provision/DSL'), 'Provision/DSL dir exists';
    ok scalar $lib_dir->subdir('Provision/DSL')->children > 10, 'provision installed';
    
}

note 'resources';
{
    Provision::DSL::Local->clear_instance;
    my $dir = Path::Class::tempdir(CLEANUP => 1);
    my $app = Provision::DSL::Local->instance;
    $app->config_file("$FindBin::Bin/../conf/test_config.pl");
    my $cache = Provision::DSL::Local::Cache->new(dir => $dir);
    
    my $resource_dir = $dir->subdir('resources');

    is scalar $resource_dir->children, 0, 'no resources';
    $cache->pack_resources;
    
    foreach my $file (qw(files/dir1/dir2/file3.txt
                         files/dir1/file1.txt
                         files/dir1/file2.txt))
    {
        ok -f $resource_dir->file($file), "Resource '$file' exists";
    }
    
    ok !-d $resource_dir->subdir('files/dirx'), 'dirx excluded from resources';
}

note 'provision script';
{
    Provision::DSL::Local->clear_instance;
    my $dir   = Path::Class::tempdir(CLEANUP => 1);
    my $app = Provision::DSL::Local->instance;
    $app->config_file("$FindBin::Bin/../conf/test_config.pl");
    my $cache = Provision::DSL::Local::Cache->new(dir => $dir);
    
    my $provision_file = $dir->file('provision.pl');
    
    ok !-f $provision_file, 'provision.pl not present';
    $cache->pack_provision_script;
    ok -f $provision_file, 'provision.pl created';
    
    is scalar $provision_file->slurp, <<'EOF', 'provision file looks good';
#!/usr/bin/env perl

my $x = 42;
our $site = 'live';

my $dir = '/path/to/x';
Done;
EOF
    
}

done_testing;
