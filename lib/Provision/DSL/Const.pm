package Provision::DSL::Const;
use base 'Exporter';

our @EXPORT = qw(
    PERLBREW_INSTALLER_URL PERLBREW_INSTALLER
);

use constant PERLBREW_INSTALLER_URL => 'http://install.perlbrew.pl';
use constant PERLBREW_INSTALLER     => 'bin/install.perlbrew.sh';

1;
