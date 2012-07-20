package Provision::DSL::Script::Provision;
use Moo;
use feature ':5.10';
use Archive::Tar;
use Archive::Tar::Constant;
use Path::Class;
use IO::String;
use MIME::Base64;
use Cwd;
use Provision::DSL::Types;
use Data::Dumper; $Data::Dumper::Sortkeys = 1;

with 'Provision::DSL::Role::CommandlineOptions',
     'Provision::DSL::Role::CommandExecution';

has config => (
    is => 'ro',
    required => 1,
    coerce => sub { do $_[0] },
);

has tar => (
    is => 'lazy',
);

sub _build_tar { Archive::Tar->new }

has script => (
    is => 'lazy',
);

sub _build_script { $_[0]->_boot_script . $_[0]->_tar_content_base64_encoded }

around options => sub {
    my ($orig, $self) = @_;

    return (
        $self->$orig,
        'config|c=s     ; specify a config file (required)',
    );
};

sub run {
    my $self = shift;

    $self->log('Starting Provisioning');

    $self->log_debug(Data::Dumper->Dump([$self->config], ['config']));

    $self->pack_requisites;

    if ($self->debug) {
        my $fh = file('/tmp/provision.pl')->openw;
        print $fh $self->script;
        $fh->close;
    }

    my $result = $self->remote_execute;
    $self->log('Script Result:', $result);

    $self->log('Finished Provisioning');
}

sub pack_requisites {
    my $self = shift;

    $self->pack_resources_and_libs;
    $self->pack_provision_script(file('examples.pl'));
}

sub pack_resources_and_libs {
    my $self = shift;

    # tar file:
    #   - resources
    #   - perl libs

    $self->_pack_dir(
        dir('/Users/wolfgang/proj/Provision-DSL/t/resources'),
        'dir1' => 'resources',
    );

    ### TODO: use cpanm to install requirements into local/
    ### TODO: don't forget Provision::DSL
    $self->_pack_dir(
        dir('/Users/wolfgang/proj/Provision-DSL'),
        'local' => '',
    );
}

sub _pack_dir {
    my ($self, $root_dir, $subdir_name, $prefix) = @_;

    my $cwd = getcwd;
    chdir $root_dir;

    my $subdir = $root_dir->subdir($subdir_name);
    $subdir->traverse( sub {
        my ($child, $cont) = @_;

        my $file = $child->relative($root_dir)->stringify;
        my $dest_file = $prefix ? "$prefix/$file" : $file;

        ### TODO: ignore if exclude glob matches

        if ($file eq '.') {
           # ignore .
        } elsif (-d $file) {
            $self->log_debug('adding DIR:', $dest_file);
            $self->tar->add_data(
                $dest_file,
                '',
                { type => DIR, mode => 0755 },
            );
        } else {
            $self->log_debug('adding FILE:', $dest_file);
            $self->tar->add_data(
                $dest_file,
                scalar $child->slurp,
                { type => FILE, mode => 0644 },
            );
        }

       return $cont->();
    });

    chdir $cwd;
}

sub pack_provision_script {
    my ($self, $script) = @_;

    $self->log_debug('adding privision script');
    $self->tar->add_data(
        'provision.pl',
        scalar $script->slurp,
        { type => FILE, mode => 0755 },
    );
}

sub _tar_content_base64_encoded {
    my $self = shift;

    my $buffer;
    my $io = IO::String->new($buffer);
    $self->tar->write($io);

    if ($self->debug) {
        $self->tar->write('/tmp/provision.tar');
    }

    return encode_base64($buffer);
}

sub remote_execute {
    my $self = shift;

    my $ssh_config = $self->config->{ssh} // {};
    my $identity_file = $ssh_config->{identity_file} || 'id_rsa';

    return $self->pipe_into_command(
        $self->script,
        '/usr/bin/ssh',
        '-i' => "$ENV{HOME}/.ssh/$identity_file",
        '-C',
        "$ssh_config->{user}\@$ssh_config->{hostname}",
        'perl -'
            . ($self->dryrun  ? ' -n' : '')
            . ($self->verbose ? ' -v' : '')
    );
}

sub _boot_script {
    my $self = shift;

    return <<'EOF';
#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Cwd;
use Archive::Tar;
use File::Temp 'tempdir';

my $cwd      = getcwd;
my $temp_dir = tempdir(CLEANUP => 1);

chdir $temp_dir;
binmode DATA, ':via(Base64Decode)';
Archive::Tar->new(\*DATA)->extract;

chdir $cwd;
$ENV{PERL5LIB} = "$temp_dir/local/lib/perl5";
system "$temp_dir/provision.pl", @ARGV;

{
    package Base64Decode;
    use MIME::Base64;

    sub PUSHED {
        my ($class, $mode, $fh) = @_;

        my $buf = '';
        return bless \$buf, $class;
    }

    sub FILL {
        my ($obj, $fh) = @_;

        my $line = <$fh>;
        return defined $line
            ? decode_base64($line)
            : undef;
    }
}

# data contains base-64 encoded tar file, compression via ssh -C
__DATA__
EOF
}

1;
