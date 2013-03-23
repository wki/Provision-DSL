use strict;
use warnings;
use Test::More;
use FindBin;
use Path::Class;

use ok 'Provision::DSL::Local::Config';
use ok 'Provision::DSL::Local';

my $config_dir = dir($FindBin::Bin)->resolve->parent->subdir('conf');

note 'config file handling';
{
    local $SIG{__WARN__} = sub {};
    
    my $missing_config_file = $config_dir->file('missing_config.pl');
    my $invalid_config_file = $config_dir->file('invalid_config.pl');
    my $good_config_file    = $config_dir->file('test_config.pl');

    is_deeply 
        +Provision::DSL::Local::Config->new->_file_content,
        {},
        'no config file defaults to {}';

    is_deeply 
        +Provision::DSL::Local::Config->new->_file_content,
        {},
        'no config file defaults to {}';

    is_deeply 
        +Provision::DSL::Local::Config->new(file => $missing_config_file)->_file_content,
        {},
        'missing config file defaults to {}';

    is_deeply 
        +Provision::DSL::Local::Config->new(file => $invalid_config_file)->_file_content,
        {},
        'invalid config file defaults to {}';

    my $c = Provision::DSL::Local::Config->new(file => $good_config_file);
    is ref $c->_file_content, 'HASH', 'config is HASH';
    is scalar keys %{$c->_file_content}, 5, '5 keys in config';
}

note 'merging config keys';
{
    my $config_file = $config_dir->file('test_config.pl');
    
    my $c = Provision::DSL::Local::Config->new(
        file => $config_file,
    );
    
    is_deeply $c->_merged_config, merged_config(), 'config merge OK';
}

note 'obtaining attributes from config values';
{
    my $config_file = $config_dir->file('test_config.pl');
    
    my $c = Provision::DSL::Local::Config->new(
        file => $config_file,
    );
    
    is  $c->name, 
        'testing', 
        'name from config';
    
    is  $c->provision_file, 
        't/conf/include_test.pl', 
        'provision_file from config';
    
    is_deeply $c->resources,
        merged_config()->{resources},
        'resources from config';
    
    is_deeply $c->local,
        merged_config()->{local},
        'local from config';
    
    is_deeply $c->remote,
        merged_config()->{remote},
        'remote from config';
}

note 'overwriting attributes from app attributes';
{
    my $config_file = $config_dir->file('test_config.pl');
    my $app = Provision::DSL::Local->instance;
    
    $app->hostname('hhhhost');
    $app->user('uuuser');
    $app->provision_file('x/pfile.pl');
    
    my $c = Provision::DSL::Local::Config->new(
        file => $config_file,
    );
    
    is $c->app, $app, 'app is OK';
    
    ### TODO: $c->name but must be missing in config for checking
    
    is  $c->remote->{hostname},
        'hhhhost',
        'host from app';
    
    is  $c->remote->{user},
        'uuuser',
        'user from app';
}

done_testing;

sub merged_config {
    +{
        name           => 'testing', # file
        
        provision_file => 't/conf/include_test.pl', # file
        
        local          => {
            cpan_http_port => 2080,
            cpanm          => 'cpanm',
            cpanm_options  => [],
            environment    => { # file
                bar => 'some thing',
                foo => 42
            },
            rsync         => 'rsync',
            rsync_modules => {},
            rsync_port    => 2873,
            ssh           => 'ssh',
            ssh_options   => [
                '-q',                  '-x', '-C', '-R',
                '2080:127.0.0.1:2080', '-R', '2873:127.0.0.1:2873'
            ]
        },
        remote => {
            environment => {
                PROVISION_HTTP_PORT  => 2080,
                PROVISION_PERL       => 'perl',
                PROVISION_RSYNC      => 'rsync',
                PROVISION_RSYNC_PORT => 2873,
                XX42                 => 'foo'
            },
            hostname => 'box'
        },
        resources => [
            {
                destination => 'files',
                exclude     => 'dirx',
                source      => 't/resources'
            }
        ]
      }
}