#!/usr/bin/env perl
#
# sample config file for storing a public ssh key on a remote machine
#
#     provision.pl -c examples/ssh_key.conf user@hostname
#
use Provision::DSL;

my $SSH_DIR = "$ENV{HOME}/.ssh";

Dir $SSH_DIR;

File "$SSH_DIR/authorized_keys" => {
    patches => [
        {
            append_if_missing => Resource('ssh/id_rsa.pub'),
        },
    ],
};

Done;
