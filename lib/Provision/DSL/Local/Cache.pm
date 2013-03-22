package Provision::DSL::Local::Cache;
use Moo;
use Provision::DSL::Types;

with 'Provision::DSL::Role::Local';

has dir => (
    is       => 'ro',
    required => 1,
);

sub BUILD {
    my $self = shift;
    
    $_->mkpath for grep { !-d }
                   map { $self->dir->subdir($_) }
                   qw(bin lib log resources);
}

sub populate {
    my $self = shift;
    
    $self->pack_perlbrew_installer;
    $self->pack_dependent_libs;
    $self->pack_provision_libs;
    $self->pack_resources;
    $self->pack_provision_script;
}

sub pack_perlbrew_installer {
    my $self = shift;

    my $installer_file = $self->cache_dir->file(PERLBREW_INSTALLER);
    return if -f $installer_file;

    $self->log('loading perlbrew installer');

    ### FIXME: does not work.
    ### HTTP::Tiny version 0.017 works when IO::Socket::SSL is installed
    # alternative:
    # curl -L http://install.perlbrew.pl -o .provision_lib/bin/install.perlbrew.sh

    try {
        $installer_file->dir->mkpath;
        my $installer = $self->http_get(PERLBREW_INSTALLER_URL);
        $installer_file->spew($installer);
        chmod 0755, $installer_file;
    } catch {
        die 'Could not load Perlbrew installer. ' .
            'Are you online? Is IO::Socket::SSL installed?';
    };
}

sub pack_dependent_libs {
    my $self = shift;

    $self->log(' - packing dependent libs');

    my @install_libs = qw(
        autodie Moo Role::Tiny Try::Tiny IPC::Run3
        Module::Pluggable Module::Load
        MRO::Compat Class::C3 Algorithm::C3
        HTTP::Tiny Template::Simple
        Path::Class File::Zglob
    );

    foreach my $lib (@install_libs) {
        my $lib_filename = "lib/perl5/$lib.pm";
        $lib_filename =~ s{::}{/}xmsg;
        $self->log_debug("checking for lib file '$lib_filename'");
        next if -f $self->cache_dir->file($lib_filename);

        $self->log_debug("packing lib '$lib' into ${\$self->cache_dir}");
        run3 [
                $self->config->{local}->{cpanm},
                -L => $self->cache_dir, '--notest',
                @{$self->config->{local}->{cpanm_options}},
                $lib
            ],
            \undef, \undef, \undef;
    }
}

sub pack_provision_libs {
    my $self = shift;

    $self->log(' - packing provision libs');

    # Provision::DSL libs are collected manually for two reasons:
    #   - we do not catch dependencies for the controlling machine
    #   - if add-ons are present, we get them, too
    my $this_file = file(__FILE__)->resolve->absolute;

    # points to "Provision/" dir (where Provision::DSL is installed)
    my $provision_dsl_dir = $this_file->dir->parent->parent;

    $self->_pack_file_or_dir(
        $_ => 'lib/perl5/Provision/',
        [ '*.pod' ],
    ) for $provision_dsl_dir->children;
}

sub _pack_file_or_dir {
    my $self     = shift;
    my $source   = shift;
    my $target   = shift;
    my @exclude  = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
    
    # rsync fails when trying to copy something to a destionation
    # with missing parent directory. Must create the parent directory
    # for the entity to get copied
    my $target_dir = $self->cache_dir->file($target)->parent;
    $target_dir->mkpath if !-d $target_dir;

    # Caution: $target might contain a trailing '/'.
    #          therefore we must join strings instead of ->subdir()
    run3 [
        $self->config->{local}->{rsync},
        '--checksum', '--recursive', '--perms', '--delete',
        ( map { ('--exclude' => $_) } @exclude ),
        $source => join('/', $self->cache_dir, $target),
    ];
}

sub pack_resources {
    my $self = shift;

    $self->log(' - packing resources');

    my $resources = $self->config->{resources}
        or return;

    if (ref $resources eq 'ARRAY') {
        $self->pack_resource($_) for @$resources;
    } else {
        $self->pack_resource($resources);
    }
}

sub pack_resource {
    my ($self, $resource) = @_;

    my $source_path = dir($resource->{source});
    my $source = $source_path->is_absolute
        ? $source_path
        : $self->root_dir->subdir($source_path);
    $source .= '/' if -d $source;

    my $target = 'resources/' . ($resource->{destination} || $resource->{source});

    $self->_pack_file_or_dir(
        $source => $target,
        $resource->{exclude} || [],
    );
}

sub pack_provision_script {
    my $self = shift;

    my $provision_file_name = $self->config->{provision_file} || 'provision.pl';
    my $cache_dir = $self->root_dir->file($provision_file_name)->dir;
    my $provision_script = scalar $self->root_dir->file($provision_file_name)->slurp;

    $provision_script =~ s{^ \s*
                           [Ii]nclude\s+            # 'include' keyword
                           (\w+)                    # $1: file to include
                           (?: \s* , \s* (.+?) )?   # $2: optional arglist
                           \s* ; \s*                # closing semicolon
                           (?: [#] .*? )?           # optional comment
                           $
                           }{$self->_include($cache_dir->file("$1.pl"), $2)}exmsg;

    $self->log(" - packing provision script '$provision_file_name'");
    # warn $provision_script; die 'stop for testing';
    $self->must_have_valid_syntax($provision_script);

    $self->cache_dir->file('provision.pl')->spew($provision_script);
}

sub _include {
    my $self = shift;
    my $file = shift;
    my $args = shift || '';

    my @content;
    my @variables = (eval $args); # keep order of variables
    while (my ($name, $value) = splice @variables, 0, 2) {
        push @content, 'our ' . Data::Dumper->Dump([$value], [$name]);
    }

    push @content, $file->slurp(chomp => 1);

    return join "\n", @content;
}

sub must_have_valid_syntax {
    my $self = shift;
    
    $self->log_debug('Syntax-Checking DSL script');

    my $perl = $Config{perlpath} || 'perl';
    my $dsl = $self->file->slurp;

    my $stderr;
    run3 [$perl, '-c', '-'], \$dsl, \undef, \$stderr;
    die "Error Checking provision script:\n$stderr" if $? >> 8;
}

1;
