package Provision::DSL::Const;
use base 'Exporter';

our @EXPORT = qw(
    PERLBREW_INSTALLER_URL PERLBREW_INSTALLER
    RSYNC RSYNC_PORT PERL HTTP_PORT 
    CAT CRONTAB CP MKDIR PS RM SH SUDO TEE
);

use constant PERLBREW_INSTALLER_URL => 'http://install.perlbrew.pl';
use constant PERLBREW_INSTALLER     => 'bin/install.perlbrew.sh';

# always transported to controlled machine
use constant RSYNC      => $ENV{PROVISION_RSYNC}        // '/usr/bin/rsync';
use constant RSYNC_PORT => $ENV{PROVISION_RSYNC_PORT}   // 2873;
use constant PERL       => $ENV{PROVISION_PERL}         // '/usr/bin/perl';
use constant HTTP_PORT  => $ENV{PROVISION_HTTP_PORT}    // 2080;

# not transported but theoretically overridable
use constant CAT        => $ENV{PROVISION_CAT}          // '/bin/cat';
use constant CP         => $ENV{PROVISION_CP}           // '/bin/cp';
use constant CRONTAB    => $ENV{PROVISION_CRONTAB}      // '/usr/bin/crontab';
use constant MKDIR      => $ENV{PROVISION_MKDIR}        // '/bin/mkdir';
use constant PS         => $ENV{PROVISION_PS}           // '/bin/ps';
use constant RM         => $ENV{PROVISION_RM}           // '/bin/rm';
use constant SH         => $ENV{PROVISION_SH}           // '/bin/sh';
use constant SUDO       => $ENV{PROVISION_SUDO}         // '/usr/bin/sudo';
use constant TEE        => $ENV{PROVISION_TEE}          // '/bin/tee';

1;
