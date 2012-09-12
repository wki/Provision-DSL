package Provision::DSL::Util;
use base 'Exporter';

our @EXPORT_OK = qw(
    remove_recursive
    os
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

#
# determine the OS of the running system
# currently we only distinguish OS-X from Ubuntu Linux
#
sub os {
    if ($^O eq 'darwin') {
        return 'OSX';
    } else {
        return 'Ubuntu'; ### FIXME: maybe wrong!
    }
}

1;
