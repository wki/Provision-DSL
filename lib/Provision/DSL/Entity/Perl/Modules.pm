package Provision::DSL::Entity::Perl::Modules;
use Moo;
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

sub inspect {
    my $self = shift;
    
    return 'missing' if !-d $self->install_dir || !scalar($self->install_dir->children);
    
    # Strategy:
    #   - list all direct dependencies of our app
    #   - paste them into a perl interpreter trying to require the modules
    #     stop as soon as the first required module is not found
    
    my $required_modules =
        $self->run_command(
            $self->perl,
            $self->cpanm, 
            '-q',
            '--showdeps' => $self->app_dir);
    
    my $has_all_modules = 0;
    try {
        $self->pipe_into_command(
            $required_modules,
            $self->perl,
            '-I' => $self->install_dir->subdir('lib/perl5'),
            '-n',
            '-e' => 's{~.*|\\s+\\z}{}xms; eval "require $_" or die "missing: $_"'
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
        $self->perl,
        $self->cpanm, 
        '-q',
        '-L' => $self->install_dir,
        '--installdeps' => $self->app_dir);
}

sub remove {
    # TODO: remove local_lib ?
}

1;
