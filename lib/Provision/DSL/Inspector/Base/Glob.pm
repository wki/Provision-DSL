package Provision::DSL::Inspector::Base::Glob;
use Moo;
use File::Zglob;
use Path::Class;

extends 'Provision::DSL::Inspector';

# may get overloaded in child classes
sub filter { 1 }

sub BUILDARGS {
    my $class = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    
    $args{expected_value} = [
        grep { $class->filter($_) }
        map { -d $_ ? dir($_) : file($_) }
        map { zglob $_ }
        map { ref $_ eq 'ARRAY' ? @$_ : $_ }
        grep { defined $_ ? $_ : () }
        $args{expected_value}
    ];

    return \%args;
}

1;
