use strict;
use warnings;
use Test::More;
use Path::Class;

use ok 'Provision::DSL::Local::Cache';
use ok 'Provision::DSL::Local';

my $dir = Path::Class::tempdir(CLEANUP => 1);
is join('|', sort map {$_->basename} $dir->children),
   '',
   'no subdirs present';

my $cache = Provision::DSL::Local::Cache->new(dir => $dir);
is join('|', sort map {$_->basename} $dir->children),
   'bin|lib|log|resources',
   '4 subdirs created';

### TODO: add more


done_testing;
