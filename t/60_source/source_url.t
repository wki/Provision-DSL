use strict;
use warnings;
use Test::More;

use ok 'Provision::DSL::Source::Url';

my $ip = gethostbyname('www.cpan.org')
    or do {
        diag 'Not connected to the internet, skipping';
        done_testing;
        exit;
    };

my $u = Provision::DSL::Source::Url->new('http://perldoc.perl.org/');
like $u->content, qr{<title>.*Perl.*</title>}xms,
     'html content looks good';

done_testing;
