package Provision::DSL::TraitFor::Perlbrew::InstallCpanm;
use Moo::Role;

sub cpanm { $_[0]->perlbrew_dir->file('bin/cpanm') }

sub _cpanm_installed { -f $_[0]->cpanm }

around state => sub {
    my $orig = shift;
    my $self = shift;
    
    my $state = $self->_cpanm_installed ? 'current' : 'missing';
    $self->$orig($state, @_);
};

after ['create', 'change'] => sub {
    my $self = shift;
    
    return if $self->_cpanm_installed;
    
    $self->log_debug('installing cpanm');
    $self->run_command_as_user($self->perlbrew, 'install-cpanm');
};

1;
