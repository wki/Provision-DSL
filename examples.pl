#!/usr/bin/env perl
use Provision::DSL;

User 'sites';
User sites => ( ... );
User sites => { ... };

Perlbrew sites => {
    install_cpanm => 1,
    install_perl  => '5.14.2',
    switch_perl   => '5.14.2',
};

File '/path/to/file.ext' => {
    user    => 'sites', # group taken from user
    content => Url('http://domain.tld/path/to/file.ext'),
};

Dir '/path/to/website' => {
    user => 'sites',
    mkdir => [qw(
        logs
        pid
    )];
};

Dir '/path/to/website/MyApp' => {
    user => 'sites',
    content => Resource('website'),
    mkdir => [qw(
        MyApp/local
        MyApp/root/cache
        MyApp/root/files
        MyApp/root/static/_css
        MyApp/root/static/_js
    )],
};

Execute install_MyApp_modules => {
    path => Perlbrew('sites')->cpanm,
    arguments => [
        '-L'            => '/path/to/website/MyApp/local',
        '--installdeps' => '/path/to/website/MyApp',
    ],
    listen => Dir('/path/to/website/MyApp'),
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
