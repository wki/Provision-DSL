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
    
    if (exists $args{expected_values} 
        && ref $args{expected_values} eq 'ARRAY'
        && scalar @{$args{expected_values}})
    {
        $args{expected_values} = [
            grep { $class->filter($_) }
            map { -d ? dir($_) : file($_) }
            map { zglob $_ }
            @{$args{expected_values}}
        ];
    }
    
    return \%args;
}

1;
