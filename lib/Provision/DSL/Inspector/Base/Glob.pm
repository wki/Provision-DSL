package Provision::DSL::Inspector::Base::Glob;
use Moo;
use Try::Tiny;
use Path::Class;
use Module::Load;

extends 'Provision::DSL::Inspector';

# File::Zglob requires perl 5.8.8 try to get it running
try { load File::Zglob; File::Zglob->import() };

# may get overloaded in child classes
sub filter { 1 }

sub BUILDARGS {
    my $class = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    
    # fall back to perl's glob if zglob is not available.
    # will result in incompatible things. Be careful!
    my $glob = $class->can('zglob') || \&CORE::GLOBAL::glob;
    
    $args{expected_value} = [
        grep { $class->filter($_) }
        map { -d $_ ? dir($_) : file($_) }
        map { $glob->($_) }
        map { ref $_ eq 'ARRAY' ? @$_ : $_ }
        grep { defined $_ ? $_ : () }
        $args{expected_value}
    ];

    return \%args;
}

1;
