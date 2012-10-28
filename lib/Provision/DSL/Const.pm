package Provision::DSL::Const;
use base 'Exporter';

our @EXPORT = qw(
    PERLBREW_INSTALLER_URL PERLBREW_INSTALLER
    RSYNC RSYNC_PORT PERL HTTP_PORT 
    CP MKDIR PS RM SH SUDO
);

use constant PERLBREW_INSTALLER_URL => 'http://install.perlbrew.pl';
use constant PERLBREW_INSTALLER     => 'bin/install.perlbrew.sh';

# always transported to controlled machine
use constant RSYNC      => $ENV{PROVISION_RSYNC}        // '/usr/bin/rsync';
use constant RSYNC_PORT => $ENV{PROVISION_RSYNC_PORT}   // 2873;
use constant PERL       => $ENV{PROVISION_PERL}         // '/usr/bin/perl';
use constant HTTP_PORT  => $ENV{PROVISION_HTTP_PORT}    // 2080;

# not transported but theoretically overridable
use constant CP         => $ENV{PROVISION_CP}           // '/bin/cp';
use constant MKDIR      => $ENV{PROVISION_MKDIR}        // '/bin/mkdir';
use constant PS         => $ENV{PROVISION_PS}           // '/bin/ps';
use constant RM         => $ENV{PROVISION_PS}           // '/bin/rm';
use constant SH         => $ENV{PROVISION_SH}           // '/bin/sh';
use constant SUDO       => $ENV{PROVISION_SUDO}         // '/usr/bin/sudo';

1;
