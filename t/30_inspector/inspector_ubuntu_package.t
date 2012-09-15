use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use Provision::DSL::Util 'os';
require "$FindBin::Bin/../inc/mock_entity.pm";

use ok 'Provision::DSL::Inspector::_Ubuntu::Package';

SKIP: {
    skip 'Can run un Ubuntu only', 2 if os ne 'Ubuntu';
    
    # perl package
    {
        my $e = E->new(name => 'perl');
        my $i = Provision::DSL::Inspector::_Ubuntu::Package->new(
            entity => $e,
            );
    
        is $i->state, 'current', 'package perl reports as installed';
    }
    
    # nonsense package
    {
        my $e = E->new(name => 'nonsense');
        my $i = Provision::DSL::Inspector::_Ubuntu::Package->new(
            entity => $e,
            );
    
        is $i->state, 'missing', 'package nonsense reports as missing';
    }
}

done_testing;
