package Provision::DSL::Entity::User;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';
# with 'Provision::DSL::Role::Group';

### FIXME: how do we ensure group existence?

our $START_UID = 1000;
our $MAX_ID    = 2000;

has uid => (
    is  => 'lazy',
    isa => Int,
);

has home_dir => (
    is     => 'lazy',
    coerce => to_Dir,
);

# _build_home_dir is OS-dependent
sub _build_home_dir {
    my $self = shift;
    
    return (getpwuid($self->uid))[7] // "/home/${\$self->name}"; # /
}

sub _build_uid {
    my $self = shift;
    
    my $uid = (getpwnam($self->name))[2];
    return $uid if defined $uid;
    
    $uid = $START_UID;
    while (++$uid < $MAX_ID) {
        next if defined getpwuid($uid);
        
        $self->log_debug("Auto-created UID: $uid");
        return $uid;
    }
    
    die 'could not create a unique UID';
}

before calculate_state => sub {
    my $self = shift;
    
    $self->add_to_state(
        defined getpwnam($self->name)
            ? 'current'
            : 'missing'
    );
};

# creation/removal is OS-dependent

1;
