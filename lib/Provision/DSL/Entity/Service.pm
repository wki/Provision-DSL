package Provision::DSL::Entity::Service;
use Moo;

extends 'Provision::DSL::Entity::File';

# sub BUILD {
#     my $self = shift;
#     
#     warn 'Service::BUILD';
#     
#     # avoid exception in File
#     if (!$self->has_patches) {
#         $self->patches([]);
#     }
# }

sub _allow_remove { 0 }
sub _strict_args  { 0 }

before state => sub {
    my $self = shift;
    
    if ($self->_service_running) {
        $self->set_state('missing');
    } else {
        $self->set_state('current');
    }
};

# start service after a possible file creation
after ['create', 'change'] => sub {
    my $self = shift;
    
    $self->_stop_service;
    $self->_install_service;
    $self->_start_service;
};

# stop service before a possible file removal
before remove => sub {
    my $self = shift;
    
    $self->_stop_service;
};

1;
