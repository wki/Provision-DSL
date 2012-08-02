#!/usr/bin/env perl
use Provision::DSL;
my $WEB_DIR     = '/web/data';
my $SITE_DIR    = "$WEB_DIR/www.mysite.de";

Package 'build-essential';

Service 'nginx';

Perlbrew {
    install_cpanm => 1,
    # wanted  => '5.14.2',
    wanted  => '5.16.0',
};

Dir $WEB_DIR => {
    user => 'root',
    permission => '0755',
};

__END__

User sites => {
    uid => 513,
};

Dir $SITE_DIR;

File "$SITE_DIR/testfile" => {
    content => 'blabla',
};

Perlbrew {
    install_cpanm => 1,
    wanted  => '5.14.2',
};

exit;

Perlbrew sites => {
    install_cpanm => 1,
    wanted        => '5.14.2',
    switch_perl   => '5.14.2',
};

File '/path/to/file.ext' => {
    user    => 'sites', # group taken from user
    content => Url('http://domain.tld/path/to/file.ext'),
};

Dir '/path/to/website' => {
    user => 'sites',
    content => Resource('website'), # has a MyApp directory
    
    # MyApp must be missing in the mkdir array!
    mkdir => [qw(
        logs
        pid
        MyApp/local
        MyApp/root/cache
        MyApp/root/files
        MyApp/root/static/_css
        MyApp/root/static/_js
    )],
    
    tell => 'source_changed',
};

Execute install_cpan_modules => {
    path => Perlbrew('sites')->cpanm,
    cwd => '/path/to/website/MyApp',
    arguments => [
        '-L'            => 'local',
        '--installdeps' => '.',
    ],
    
    # too dangerous because a deletion in local is not discovered.
    # listen => Dir('/path/to/website/MyApp'),
};

File '/path/to/website/MyApp/static/_css/site.css' => {
    content => Execute('/path/to/binary'),
    only_if => FileNewer('/path/to/website/MyApp/static/css/*.css'),
},

Execute db_migration => {
    path => '/path/to/website/MyApp/script/db_migration.pl',
};

Service plack_server => {
    user => 'sites',
    runlevel => [2,3],
    copy => Resource('...'),
    listen => 'source_changed',
};

Service thumbnail_hotfolder => {
    user => 'sites',
    runlevel => [2,3],
    copy => Resource('...'),
    listen => 'source_changed',
};


__END__

# ----- general parameter syntax:

Keyword;                    # usually dies, name is required

Keyword 'name';
Keyword name => ( ... );    # maybe unclever
Keyword name => { ... };
Keyword { ... };

Keyword();
Keyword('name');
Keyword(name => { ... });
Keyword({ ... });
