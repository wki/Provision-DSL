package Provision::DSL::Entity::User;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';
# with 'Provision::Role::Group';

### FIXME: how do we ensure group existence?

our $START_UID = 1000;
our $MAX_ID    = 2000;

has uid => (
    is => 'lazy',
    isa => Int,
);

has home_directory => (
    is => 'lazy',
    coerce => to_Dir,
);

has gid => (
    is => 'lazy',
    isa => Int,
    coerce => to_Gid,
);

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

sub _build_gid {
    my $self = shift;
    
    my $gid = (getpwnam($self->name))[3];
    if (defined $gid) {
        return $gid;
    } else {
        ### FIXME : search for group return $self->name;
    }
}

around is_present => sub {
    my ($orig, $self) = @_;
    
    return defined getpwnam($self->name) && $self->$orig();
};

before create => sub {
    my $self = shift;

    $self->log_dryrun("would create User home_directory '${\$self->home_directory}'")
        and return;

    # $self->home_directory->mkpath;
    # chown $self->uid, $self->group->gid, $self->home_directory;
};

1;
