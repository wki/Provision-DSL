package Provision::DSL::Util;
use base 'Exporter';

our @EXPORT_OK = qw(
    remove_recursive
);

#
# useful for Path::Class::Dir::traverse
#   $dir->traverse(\&remove_recursive)
#
sub remove_recursive {
    my ($child, $cont) = @_;

    $cont->() if -d $child;
    $child->remove;
}

1;
