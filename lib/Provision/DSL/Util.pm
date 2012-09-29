package Provision::DSL::Util;
use base 'Exporter';

our @EXPORT_OK = qw(
    os
);

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
