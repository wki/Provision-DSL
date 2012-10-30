#!/usr/bin/env perl
#
# sample provision file for a host named 'box' (my virtual box)
#     provision.pl -c examples/box.conf
#
use Provision::DSL;
my $WEB_DIR     = '/web/data';
my $SITE_DIR    = "$WEB_DIR/www.mysite.de";

Package 'build-essential';

# Service 'nginx';

Perlbrew {
    # install_cpanm => 1,
    # wanted  => '5.14.2',
    wanted  => '5.16.0',
};

Dir $WEB_DIR => {
    user => 'root',
    permission => '0755',
};

Dir $SITE_DIR => {
    user => 'vagrant',
    group => 'vagrant',
    content => Resource('files'),
};

Done;

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
        app/local
        app/root/cache
        app/root/files
        app/root/static/_css
        app/root/static/_js
    )],
};

### BETTER:
Perl_Modules '/path/to/website/MyApp/local' => {
    perl => Perlbrew->perl,
    cpanm => Perlbrew->cpanm,
    
    # optional: a CPAN mirror to use
    mirror => '',
    
    # --installdeps from a distribution dir
    installdeps => '/path/to/website/MyApp',
    
    # manually picked modules or tarballs
    install => [
        'Package::Name',
        'Package-Name-0.07.tar.gz',
        Resource('modules/my_package'),
    ],
};

File '/path/to/website/MyApp/static/_css/site.css' => {
    content => Execute('/path/to/binary'),
},

Execute db_migration => {
    path => '/path/to/website/MyApp/script/db_migration.pl',
};

Service plack_server => {
    user => 'sites',
    runlevel => [2,3],
    copy => Resource('...'),
};

Service thumbnail_hotfolder => {
    user => 'sites',
    runlevel => [2,3],
    copy => Resource('...'),
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
