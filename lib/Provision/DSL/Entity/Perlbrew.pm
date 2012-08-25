package Provision::DSL::Entity::Perlbrew;
use Moo;
use Try::Tiny;
use Provision::DSL::Types;
use Provision::DSL::Source::Bin;

extends 'Provision::DSL::Entity::Compound';
with    'Provision::DSL::Role::CommandExecution',
        'Provision::DSL::Role::User',
        'Provision::DSL::Role::Group',
        'Provision::DSL::Role::HTTP';

# has install_cpanm => (
#     is      => 'ro',
#     isa     => Bool,
#     default => sub { 0 },
# );

has install_perl => (
    is       => 'lazy',
    isa      => PerlVersion,
    coerce   => to_PerlVersion,
);

sub _build_install_perl { $_[0]->wanted }

sub _build_name { scalar getpwuid($<) }

# sub _build_user { $_[0]->name }

has perlbrew_dir => (
    is     => 'lazy',
    coerce => to_Dir,
);

sub _build_perlbrew_dir { $_[0]->user->home_dir->subdir('perl5/perlbrew') }

has perlbrew => (
    is     => 'lazy',
    coerce => to_File,
);

sub _build_perlbrew { $_[0]->perlbrew_dir->file('bin/perlbrew') }

has perl => (
    is     => 'lazy',
    coerce => to_File,
);

sub _build_perl { $_[0]->bin('perl') }

# has cpanm => (
#     is     => 'lazy',
#     coerce => to_File,
# );
# 
# sub _build_cpanm { 
#     my $self = shift;
#     
#     $self->perlbrew_dir
#          ->file('bin/cpanm')
# }

sub bin {
    my ($self, $binary) = @_;
    
    $self->perlbrew_dir
         ->subdir('perls', $self->install_perl, 'bin')
         ->file($binary);
}

before state => sub {
    $_[0]->add_to_state(-f $_[0]->perlbrew ? 'current' : 'missing');
};

sub _build_children {
    my $self = shift;

    return [
        $self->create_entity(
            Perlbrew_Perl => {
                name    => join('_', $self->name, 'perl'),
                parent  => $self,
                install => $self->install_perl
            }
        ),
    ];
}

before create => sub {
    my $self = shift;

    # find or get perlbrew installer
    my $installer;
    try {
        $installer = Provision::DSL::Source::Bin->new('install.perlbrew.sh');
    } catch {
        # load via $self->http_get('http://install.perlbrew.pl');
        # needs temp file for install
        die 'loading perlbrew via http: not implemented';
    };

    $self->run_command_as_user('/bin/sh', $installer);
};

1;
