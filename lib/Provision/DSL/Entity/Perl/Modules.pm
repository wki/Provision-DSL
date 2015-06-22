package Provision::DSL::Entity::Perl::Modules;
use Moo;
use Try::Tiny;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';

has app_dir => (
    is => 'lazy',
    coerce => to_Dir,
);

sub _build_app_dir { $_[0]->name }

has perl => (
    is => 'ro',
    coerce => to_File,
    required => 1,
);

has cpanm => (
    is => 'ro',
    coerce => to_File,
    required => 1,
);

has install_dir => (
    is => 'lazy',
    coerce => to_Dir,
);

sub _build_install_dir { $_->app_dir->subdir('local') }

has options => (
    is => 'ro',
    default => sub { [] },
);

sub inspect {
    my $self = shift;
    
    if (!-d $self->install_dir || !scalar($self->install_dir->children)) {
        $self->log_info('module_dir missing or empty');
        return 'missing';
    }
    
    # Strategy:
    #   - list all direct dependencies of our app
    #   - paste them into a perl interpreter trying to require the modules
    #     exit 1 as soon as the first required module is not found
    
    my $required_modules =
        $self->run_command(
            $self->perl->stringify,
            $self->cpanm->stringify, 
            '-q',
            '--showdeps' => $self->app_dir);
    
    my $has_all_modules = 0;
    try {
        $self->pipe_into_command(
            $required_modules,
            $self->perl->stringify,
            '-I' => $self->install_dir->subdir('lib/perl5'),
            '-n',
            '-e' => 's{~}{ }xms; eval "use $_ (); 1" or exit 1'
            # OLD: '-e' => 's{~.*|\\s+\\z}{}xms; eval "require $_" or exit 1',
        );
        $has_all_modules = 1;
    };
    
    # FIXME: not entirely correct as we do not version-check the modules
    return $has_all_modules ? 'current' : 'outdated';
}

sub create {
    my $self = shift;
    
    $self->install_dir->mkpath() if !-d $self->install_dir;
    $self->change;
}

sub change { 
    my $self = shift;

    $self->run_command(
        $self->perl->stringify,
        $self->cpanm->stringify,
        '-q',
        '-L' => $self->install_dir->stringify,
        @{$self->options},
        '--installdeps' => $self->app_dir->stringify);
}

sub remove {
    # TODO: remove local_lib ?
}

1;
