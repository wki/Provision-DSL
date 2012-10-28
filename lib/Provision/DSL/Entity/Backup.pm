package Provision::DSL::Entity::Backup;
use Moo;
use POSIX qw(mktime strftime);
use Provision::DSL::Const;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';
with    'Provision::DSL::Role::CommandExecution';

has source_dir => (
    is => 'ro',
    coerce => to_ExistingDir,
    required => 1,
);

has backup_root_dir => (
    is => 'lazy',
    coerce => to_ExistingDir,
);

sub _build_backup_root_dir { $_[0]->name }

# keep this many backups in total
has nr_backups_total => (
    is => 'ro',
    default => sub { 10 },
);

# keep the last x backups of this day
has nr_backups_per_day => (
    is => 'ro',
    default => sub { 2 },
);

has backup_dir => (
    is => 'lazy',
    coerce => to_ExistingDir,
);

sub _build_backup_dir {
    my $self = shift;
    
    my $now = strftime('%Y%m%d_%H%M%S', localtime(time));
    my $backup_dir = $self->backup_root_dir->subdir($now);
    $backup_dir->mkpath;
    
    return $backup_dir;
}

sub clean_old_backups {
    my $self = shift;
    
    $self->_remove_dirs_until_limit(
        $self->_todays_backup_dirs, $self->nr_backups_per_day
    );
    
    $self->_remove_dirs_until_limit(
        $self->_all_backup_dirs, $self->nr_backups_total
    );
}

sub _todays_backup_dirs {
    my $self = shift;
    
    my $today_midnight = mktime(0,0,0, (localtime(time))[3..8]);
    
    return [
        grep { $_->stat->ctime >= $today_midnight }
        @{$self->_all_backup_dirs}
    ];
}

sub _all_backup_dirs {
    my $self = shift;

    return [
        sort { $a->stat->ctime <=> $b->stat->ctime }
        $self->backup_root_dir->children
    ];
}

sub _remove_dirs_until_limit {
    my ($self, $dirs, $limit) = @_;
    
    while (scalar @$dirs >= $limit) {
        my $dir = shift @$dirs;
        $self->run_command(RM, '-rf', $dir);
    }
}

sub inspect { 'outdated' }

sub create { goto \&change }
sub change {
    my $self = shift;
    
    $self->clean_old_backups;
    
    $self->run_command_as_user(
        RSYNC, 
        '--checksum',
        '--recursive',
        '--link-dest', $self->source_dir,
        '--links',
        $self->source_dir, $self->backup_dir
    );
}


1;
