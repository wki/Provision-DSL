package Provision::DSL::Entity::Cron;
use Moo;
use Try::Tiny;

extends 'Provision::DSL::Entity::Execute';

has minute => (
    is      => 'ro',
    default => sub { [ '*' ] },
    coerce  => to_Array,
);

has minutes => (
    is     => 'lazy',
    coerce => to_Array,
);

sub _build_minutes { $_[0]->minute }

has hour => (
    is      => 'ro',
    default => sub { [ '*' ] },
    coerce  => to_Array,
);

has hours => (
    is     => 'lazy',
    coerce => to_Array,
);

sub _build_hours { $_[0]->hour }

has day_of_week => (
    is      => 'ro',
    default => sub { [ '*' ] },
    coerce  => to_Array,
);

has days_of_week => (
    is     => 'lazy',
    coerce => to_Array,
);

sub _build_days_of_week { $_[0]->day_of_week }

has month => (
    is      => 'ro',
    default => sub { [ '*' ] },
    coerce  => to_Array,
);

has months => (
    is     => 'lazy',
    coerce => to_Array,
);

sub _build_months { $_[0]->month }

has day_of_month => (
    is      => 'ro',
    default => sub { [ '*' ] },
    coerce  => to_Array,
);

has days_of_month => (
    is     => 'lazy',
    coerce => to_Array,
);

sub _build_days_of_month { $_[0]->day_of_month }

sub _get_crontab_text {
    my $self = shift;
    
    my @command_and_args;
    if ($self->is_root) {
        @command_and_args = qw(/bin/cat /etc/crontab)
    } else {
        @command_and_args = qw(/usr/bin/crontab -l);
        if ($self->is_other_user) {
            push @command_and_args, '-u', $self->user;
        }
    }
    
    my $crontab_text;
    try {
        $crontab_text = $self->run_command_maybe_privileged(@command_and_args);
    };
    
    return $crontab_text;
}

sub _save_crontab_text {
    my ($self, $text) = @_;
    
    my $command;
    my @args;
    if ($self->is_root) {
        $command = '/usr/bin/tee';
        @args = qw(/etc/crontab);
    } else {
        $command = '/usr/bin/crontab';
        if ($self->is_other_user) {
            push @args, '-u', $self->user;
        }
        push @args, '-';
    }
    
    $self->run_command_maybe_privileged($command, {stdin => $text}, @args);
}

# Strategie:
# wenn es bereits einen Block gibt, der zu dieser Datei paßt, ersetzen
# suchen nach der ersten Zeile, die Zeit-Spalten enthält, davor einfügen
#
# autocreated by Provision::DSL -- do not edit
# * * * * * eintraege...
# end Provision::DSL

### FIXME: must read /etc/crontab or execute crontab -l and check content
sub inspect { 'current' }

sub need_privilege { $_[0]->is_other_user }

### FIXME: must change /etc/crontab or execute crontab -e
# methods must be defined here to definitively override Execute's method
sub create {}
sub change {}
sub remove {}

1;
