package Provision::DSL::Entity::Group;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';

our $START_GID = 1000;
our $MAX_ID    = 2000;

has gid => (
    is => 'lazy',
    # isa => 'Int',
    # required => 1,
    # lazy_build => 1,
);

sub _build_gid {
    my $self = shift;
    
    my $gid = (getgrnam($self->name))[2];
    return $gid if defined $gid;
    
    $gid = $START_GID;
    while (++$gid < $MAX_ID) {
        next if defined getgrgid($gid);

        $self->log_debug("Auto-created GID: $gid");
        return $gid;
    }
    
    die 'could not create a unique GID';
}

# before calculate_state => sub {
#     my $self = shift;
#     
#     $self->add_to_state(
#         defined getgrnam($self->name)
#             ? 'current'
#             : 'missing'
#     );
# };

# creation/removal is OS-dependent

1;
