package Provision::DSL::TraitFor::Perlbrew::InstallCpanm;
use Moo::Role;

has install_cpanm => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0 },
);

sub cpanm { $_[0]->perlbrew_dir->file('bin/cpanm') }

sub _cpanm_installed { -f $_[0]->cpanm }

before calculate_state => sub {
    my $self = shift;
    
    $self->add_to_state('outdated') if !$self->_cpanm_installed;
};

after ['create', 'change'] => sub {
    my $self = shift;
    
    return if $self->_cpanm_installed;
    
    $self->log_debug('installing cpanm');
    $self->run_command_as_user($self->perlbrew, 'install-cpanm');
};

1;
