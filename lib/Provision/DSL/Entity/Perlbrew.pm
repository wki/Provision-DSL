package Provision::DSL::Entity::Perlbrew;
use Moo;
use LWP::Simple;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Compound';
# with 'Provision::Role::User';

has install_cpanm => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0 },
);

has install_perl => (
    is  => 'lazy',
    isa => PerlVersion,
);

sub _build_install_perl { $_->wanted }

has switch_to_perl => (
    is  => 'ro',
    isa => Str,
);

sub _build_user { $_[0]->name }

around state => sub {
    my ($orig, $self) = @_;
    
    
    # !-d $self->path
    #     ? 'missing'
    # : $self->$orig() eq 'current'
    #     ? 'current'
    #     : 'outdated';
};

sub _build_children {
    my $self = shift;

    return [
        $self->create_entity(
            Perlbrew_Install => { user => $self->user, parent => $self }
        ),
        $self->create_entity(
            Perlbrew_Cpanm => { user => $self->user, parent => $self }
        ),
        $self->create_entity(
            Perlbrew_Perl => {
                user    => $self->user,
                parent  => $self,
                install => $self->install_perl
            }
        ),
        $self->create_entity(
            Perlbrew_Switch => {
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
