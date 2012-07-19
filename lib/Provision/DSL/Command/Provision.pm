package Provision::DSL::Command::Provision;
use Moo;
use feature ':5.10';
use Archive::Tar;
use Archive::Tar::Constant;
use Path::Class;
use IO::String;
use MIME::Base64;
use Cwd;
use Provision::DSL::Types;

with 'Provision::DSL::Role::AppOptions',
     'Provision::DSL::Role::Command';

has config => (
    is => 'ro',
    required => 1,
    coerce => sub { do $_[0] },
);

has tar => (
    is => 'lazy',
);

sub _build_tar { Archive::Tar->new }

sub extra_options {
    return 'config|c=s;specify a config file (required)'
}

sub run {
    my $self = shift;

    $self->log('Starting Provisioning');

    $self->pack_requisites;
    my $script = $self->create_boot_script;
    
    if ($self->debug) {
        my $fh = file('/tmp/provision.pl')->openw;
        print $fh $script;
        $fh->close;
    }
    
    # my $result = $self->remote_execute($script);
    # $self->log($result);

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

sub create_boot_script {
    my $self = shift;

    return $self->_boot_script
        .  $self->_tar_content_base64_encoded;
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
    my ($self, $script) = @_;

    # $ cat this_script.pl | ssh -x -C <<host>> perl
    return $self->pipe_into_command(
        $script,
        '/usr/bin/ssh',
        # -i key_name
        # -C
        # user @ host
        'perl'
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

my $cwd      = getgwd;
my $temp_dir = tempdir(CLEANUP => 1);

chdir $temp_dir;
binmode DATA, ':via(Base64)';
Archive::Tar->new(\*DATA)->extract;

chdir $cwd;
system "$temp_dir/provision.pl";

{
   package Base64;
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
