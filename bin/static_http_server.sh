#!/bin/sh
#
# just a demo for using a Pinto repository via an ssh tunnel
#
plackup \
    -M Plack::App::File \
    -e 'Plack::App::File->new(root => "/Users/wolfgang/tmp/repo")->to_app'

### example for building a repo
# mkdir repo
# pinto -rrepo init
# pinto -rrepo props -P target_perl_version=v5.10.0
# pinto -rrepo pull -M Moo
