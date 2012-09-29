use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
# use Path::Class;

use ok 'Provision::DSL::Types';

# my $t_dir = dir($FindBin::Bin)->parent;

### TODO: also test the more trivial cases

# to_Class
{
    no strict 'refs';
    no warnings 'redefine';
    local *Provision::DSL::Types::os = sub { 'OSX' };
    
    my $c = to_Class('Provision::DSL::Inspector');
    
    dies_ok { $c->('NotExistingClass') } 'coercing a not existing class dies';
    
    ### currently we do not have OS-Inspectors
    # # fails but should work:
    # is $c->('Package'), 'Provision::DSL::Inspector::_OSX::Package',
    #     'a OS-specific Class is found';
    
    is $c->('Always'), 'Provision::DSL::Inspector::Always',
        'a not OS-Specific Class is found';
}

# to_ClassAndArgs
{
    no strict 'refs';
    no warnings 'redefine';
    local *Provision::DSL::Types::os = sub { 'OSX' };
    
    my $c = to_ClassAndArgs('Provision::DSL::Inspector');
    
    is_deeply $c->('Never'), [ 'Provision::DSL::Inspector::Never', {} ],
        'string instantiation works';
    
    ok !defined $c->(), 'empty class coercion gives undef';
    ok !defined $c->(''), 'empty string class coercion gives undef';
}

done_testing;
