package Provision::DSL::Const;
use base 'Exporter';

our @EXPORT = qw(
    PERLBREW_INSTALLER_URL PERLBREW_INSTALLER
    RSYNC RSYNC_PORT PERL HTTP_PORT SUDO SH PS
);

use constant PERLBREW_INSTALLER_URL => 'http://install.perlbrew.pl';
use constant PERLBREW_INSTALLER     => 'bin/install.perlbrew.sh';

use constant RSYNC      => $ENV{PROVISION_RSYNC}        // '/usr/bin/rsync';
use constant RSYNC_PORT => $ENV{PROVISION_RSYNC_PORT}   // 2873;
use constant PERL       => $ENV{PROVISION_PERL}         // '/usr/bin/perl';
use constant HTTP_PORT  => $ENV{PROVISION_HTTP_PORT}    // 2080;
use constant SUDO       => $ENV{PROVISION_SUDO }        // '/usr/bin/sudo';
use constant SH         => $ENV{PROVISION_SH }          // '/bin/sh';
use constant PS         => $ENV{PROVISION_PS }          // '/bin/ps';

1;
