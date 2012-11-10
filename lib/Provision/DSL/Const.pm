package Provision::DSL::Const;
use base 'Exporter';

our @EXPORT = qw(
    PERLBREW_INSTALLER_URL PERLBREW_INSTALLER
    RSYNC RSYNC_PORT PERL HTTP_PORT 
    CAT CRONTAB CHMOD CHOWN CHGRP CP CPANM CRONTAB
    LN MKDIR PS RM SH SSH SUDO TEE TOUCH TRUE
);

use constant PERLBREW_INSTALLER_URL => 'http://install.perlbrew.pl';
use constant PERLBREW_INSTALLER     => 'bin/install.perlbrew.sh';

# always transported to controlled machine
use constant RSYNC      => $ENV{PROVISION_RSYNC}        || 'rsync';
use constant RSYNC_PORT => $ENV{PROVISION_RSYNC_PORT}   || 2873;
use constant PERL       => $ENV{PROVISION_PERL}         || 'perl';
use constant HTTP_PORT  => $ENV{PROVISION_HTTP_PORT}    || 2080;

# not transported but theoretically overridable
use constant CAT        => $ENV{PROVISION_CAT}          || 'cat';
use constant CHMOD      => $ENV{PROVISION_CHMOD}        || 'chmod';
use constant CHOWN      => $ENV{PROVISION_CHOWN}        || 'chown';
use constant CHGRP      => $ENV{PROVISION_CHGRP}        || 'chgrp';
use constant CP         => $ENV{PROVISION_CP}           || 'cp';
use constant CPANM      => $ENV{PROVISION_CPANM}        || 'cpanm';
use constant CRONTAB    => $ENV{PROVISION_CRONTAB}      || 'crontab';
use constant LN         => $ENV{PROVISION_LN}           || 'ln';
use constant MKDIR      => $ENV{PROVISION_MKDIR}        || 'mkdir';
use constant PS         => $ENV{PROVISION_PS}           || 'ps';
use constant RM         => $ENV{PROVISION_RM}           || 'rm';
use constant SH         => $ENV{PROVISION_SH}           || 'sh';
use constant SSH        => $ENV{PROVISION_SSH}          || 'ssh';
use constant SUDO       => $ENV{PROVISION_SUDO}         || 'sudo';
use constant TEE        => $ENV{PROVISION_TEE}          || 'tee';
use constant TOUCH      => $ENV{PROVISION_TOUCH}        || 'touch';
use constant TRUE       => $ENV{PROVISION_TRUE}         || 'true';

1;
