package Provision::DSL::Role::CommandlineOptions;
use Moo::Role;
use Getopt::Long; # 'GetOptionsFromArray';
use Scalar::Util 'blessed';
use POSIX qw(strftime mktime);
use Provision::DSL::Types;

has verbose => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0 },
);

has debug => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0 },
);

has dryrun => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0 },
);

has args => (
    is      => 'ro',
    default => sub { [] },
);

has log_dir => (
    is        => 'lazy',
    coerce    => to_Dir,
    predicate => 1,
);

has log_filename => (
    is      => 'ro',
    default => sub { 'provision.log' },
);

has log_file => (
    is     => 'lazy',
    coerce => to_File,
);

sub _build_log_file {
    my $self = shift;

    $self->log_dir->mkpath if !-d $self->log_dir;

    my $log_file = $self->log_dir->file($self->log_filename);

    my $midnight = mktime(0,0,0, (localtime(time))[3..8]);
    if (-f $log_file && $log_file->stat->mtime <= $midnight) {
        my $mtime = $log_file->stat->mtime;
        my $archive_dir =
            $self->log_dir->subdir(
                strftime('%Y/%m', localtime($mtime))
            );
        $archive_dir->mkpath if !-d $archive_dir;
        rename $log_file
            => $archive_dir->file(sprintf('%02d.log', (localtime($mtime))[3]));
    }

    return $log_file;
}

has log_user => (
    is => 'ro',
    predicate => 1,
);

# has log_fh => (
#     is => 'lazy',
# );
# 
# sub _build_log_fh { $_[0]->log_file->open('>>') }

# expand in class/children/roles via 'around' modifier
sub options {
    return (
        'help|h         ; this help',
        'verbose|v      ; verbose mode - show messages',
        'dryrun|n       ; dryrun - do not install',
        'log_dir|l=s    ; set log dir and enable logging to files',
        'log_user|U=s   ; optional user for log entries',
        'debug          ; show debug output',
    );
}

sub new_with_options {
    my $class = shift;
    local @ARGV = @_;     # not very polite but needed in order to inject things

    my %opt;
    Getopt::Long::Configure('bundling');
    my $options_ok = GetOptions(
        \%opt,
        map {s{\s*;\s*.*}{}; $_} $class->options
    );

    $class->usage if $opt{help} || !$options_ok;
    
    return $class->new( { %opt, args => [ @ARGV ] } );
}

sub usage {
    my $class = shift;

    my $app = $0;
    $app =~ s{\A .* /}{}xms;

    my $options = '';
    $options .= $class->usage_text if $class->can('usage_text');
    foreach my $option ($class->options) {
        ### FIXME: must get cleaned up a bit
        my ($name, $comment) = split qr{\s*;\s*}xms, $option;
        $name =~ s{[!+=:].*}{}xms;
        $name =~ s{\b(\w{2,})}{--$1};
        $name =~ s{\b(\w)\b}{-$1}xmsg;
        $name =~ s{\|}{ }xmsg;
        $options .= sprintf("\n  %-20s%s", $name, $comment || '');
    }
    $options .= "\n";

    print <<EOF;
$app [options] $options

EOF
    exit 1
}

sub log {
    my $self = shift;

    $self->log_to_file(@_);

    $self->_log_if($self->verbose || $self->debug, @_);
}

sub log_to_file {
    my $self = shift;
    
    return if !$self->has_log_dir || $self->dryrun;
    
    $self->log_file->spew(
        iomode => '>>',
        join ' ',
             strftime('%d.%m.%Y %H:%M:%S %Z -', localtime(time)),
             map { _to_string($_) } @_, "\n"
    );
}

sub log_debug {
    my $self = shift;

    $self->_log_if($self->debug, 'DEBUG:', @_);
}

sub log_dryrun {
    my $self = shift;

    $self->_log_if($self->dryrun, @_);
}

sub _log_if {
    my $self = shift;
    my $condition = shift;

    if ($condition) {
        print join(' ', map { _to_string($_) } @_) . "\n";
        binmode(STDOUT);
    }

    return $condition;
}

sub _to_string {
    my $thing = shift;

    return
        !defined $thing
            ? '(undef)'
    :   !ref $thing
            ? "$thing"
    :   ref $thing eq 'ARRAY'
            ? '[ ' .
              join(', ',
                   map { _to_string($_) } @$thing) .
              ' ]'
    :   ref $thing eq 'HASH'
            ? '{ ' .
              join(', ',
                   map { "$_: ". _to_string($thing->{$_})} keys %$thing) .
              ' }'
    :   ref($thing) =~ m{\A Provision::DSL::Entity \b .* :: ([^:]+) \z}xms
            ? "$1('${\$thing->name}')"
    :   blessed $thing && $thing->can('stringify')
            ? ref($thing) .
              '<' . $thing->stringify . '>'
    :   "$thing"
}

1;
