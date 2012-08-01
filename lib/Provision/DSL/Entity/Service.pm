package Provision::DSL::Entity::Service;
use Moo;

extends 'Provision::DSL::Entity::File';

#
# /etc/init.d --> service
# /etc/rcX.d  --> je nach runlevel
#
# evtl. schon vorhanden.
# /sbin/start-stop-daemon verwenden!

# /usr/sbin/update-rc.d -- zum Ändern des runlevel


1;
