use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;

use ok 'Provision::DSL';

can_ok 'main', qw(OS Os os Done done app);

# foreach my $os (qw(OSX Ubuntu)) {
{
    my $os = $^O eq 'darwin' ? 'OSX' : 'Ubuntu';

    is os(), $os, "os is $os";
    is Os(), $os, "Os is $os";
    is OS(), $os, "OS is $os";

    Provision::DSL::instantiate_app();
    # my $app = $Provision::DSL::app;
    isa_ok app, "Provision::DSL::App::$os";
    isa_ok app, "Provision::DSL::App";

    # # save $app in class's our variable, like import() also does
    # $Provision::DSL::app = $app;

    # is_deeply app->entity_package_for, {}, "$os: no entity packages defined";
    # 
    #     lives_ok { Provision::DSL::create_and_export_entity_keywords('main') }
    #              "$os: create_and_export_entity_keywords lives";
    
    ok scalar keys %{app->entity_package_for} > 5,
       "$os: more than 5 entity packages found";

    while (my ($entity_name, $entity_package) = each %{app->entity_package_for}) {
        like $entity_name, qr{\A [A-Z][A-Za-z0-9_]+ \z}xms,
             "$os: Entity '$entity_name' has a valid name";
        like $entity_package, qr{\A Provision::DSL::Entity:: (?: _ $os ::)? [A-Z][A-Za-z0-9_:]+ \z}xms,
             "$os: Class '$entity_package' has valid namespace";

        can_ok 'main', $entity_name;
    }
}

lives_ok { Provision::DSL::create_and_export_source_keywords('main') }
         'create_and_export_source_keywords lives';

foreach my $source (qw(resource url)) {
    can_ok 'main', $source, lcfirst $source;
}

# prevent error message in Provision::DSL::END{} from firing
Provision::DSL::App->instance->is_running(1);

done_testing;
