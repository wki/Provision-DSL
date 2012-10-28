package Provision::DSL::Entity::Cron;
use Moo;
use Try::Tiny;
use Provision::DSL::Types;
use Provision::DSL::Const;

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

# [ -- entries may be undef
#    0: all leading lines (up to last variable definition)
#    1: # autocreated by Provision::DSL -- do not edit
#    2: lines before our line
#    3: --> OUR LINE <--
#    4: lines after our line
#    5: # end Provision::DSL
#    6: all trailing lines
# ]

has crontab_parts => (
    is => 'lazy',
);

sub _build_crontab_parts {
    ... # TODO: fill me
    
    # wenn "# autocreated..." enthalten, leading, block, trailing einfach
    #      innerhalb: path wird verwendet, die Zeile als "meine" zu erkennen
    # sonst: scannen nach var-definitionen, rest.
}

sub _crontab_line {
    my $self = shift;
    
    join ' ',
        (
            map { 
                my $x = join(',', $self->$_); 
                $x =~ s{\s+}{}xmsg;
                $x =~ m{\A \s* \z}xms ? '*' : $x 
            }
            qw(minutes hours days_of_month months days_of_week)
        ),
        ($self->is_root ? 'root' : ()),
        $self->path,
        @{$self->args};
}

sub _get_crontab_text {
    my $self = shift;
    
    my @command_and_args;
    if ($self->is_root) {
        @command_and_args = (CAT, '/etc/crontab')
    } else {
        @command_and_args = (CRONTAB, '-l');
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
        $command = TEE;
        push @args, '/etc/crontab';
    } else {
        $command = CRONTAB;
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
sub inspect {
    my $self = shift;
    
}

sub need_privilege { $_[0]->is_other_user }

### FIXME: must change /etc/crontab or execute crontab -e
# methods must be defined here to definitively override Execute's method
sub create {}
sub change {}
sub remove {}

1;
