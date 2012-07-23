package Provision::DSL::Entity::Perlbrew;
use Moo;
use LWP::Simple;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Compound';
with 'Provision::DSL::Role::User';

has install_cpanm => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0 },
);

has install_perl => (
    is  => 'lazy',
    isa => PerlVersion,
);

sub _build_install_perl { $_[0]->wanted }

has switch_to_perl => (
    is  => 'ro',
    isa => Str,
);

sub _build_name { scalar getpwuid($<) }
sub _build_user { $_[0]->name }

has perlbrew_dir => (
    is => 'lazy',
    coerce => to_Dir,
);

sub _build_perlbrew_dir { $_[0]->user->home_dir->subdir('perl5/perlbrew') }

has perlbrew => (
    is => 'lazy',
    coerce => to_File,
);

sub _build_perlbrew { $_[0]->perlbrew_dir->file('bin/perlbrew') }

around state => sub {
    my ($orig, $self) = @_;
    
    return !-f $self->perlbrew
        ? 'missing'
        : $self->$orig() eq 'current'
            ? 'current'
            : 'outdated';
};

sub _build_children {
    my $self = shift;

    return [
        $self->create_entity(
            Perlbrew_Install => {
                name => join('_', $self->name, 'install'),
                user => $self->user, 
                parent => $self,
            },
        ),
        $self->create_entity(
            Perlbrew_Cpanm => { 
                name => join('_', $self->name, 'cpanm'),
                user => $self->user, 
                parent => $self,
            }
        ),
        $self->create_entity(
            Perlbrew_Perl => {
                name => join('_', $self->name, 'perl'),
                user    => $self->user,
                parent  => $self,
                install => $self->install_perl
            }
        ),
        $self->create_entity(
            Perlbrew_Switch => {
                name => join('_', $self->name, 'switch'),
                user   => $self->user,
                parent => $self,
                switch => $self->switch_to_perl
            }
        ),
    ];
}

before create => sub {
    my $self = shift;

    # in tar: local/bin/install.perlbrew.sh
    my $perlbrew_install = get('http://install.perlbrew.pl')
        or die 'could not download perlbrew';

    $self->pipe_into_command($perlbrew_install,
                             '/usr/bin/su', $self->user->name);
};

1;
