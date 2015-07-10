use strict;
use warnings;
use FindBin;
use Test::More;
use Test::Exception;
use Test::Trap;

use ok 'Provision::DSL';

can_ok 'main',
    qw(OS Os os 
       Done done 
       Include include 
       app 
       Defaults);

# basic things, entity keywords
{
    my $os = $^O eq 'darwin' ? 'OSX' : 'Ubuntu';

    is os(), $os, "os is $os";
    is Os(), $os, "Os is $os";
    is OS(), $os, "OS is $os";

    Provision::DSL::instantiate_app();
    my $app = Provision::DSL::App->instance();
    isa_ok $app, "Provision::DSL::App";

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

# source
{
    lives_ok { Provision::DSL::create_and_export_source_keywords('main') }
         'create_and_export_source_keywords lives';

    foreach my $source (qw(resource url)) {
        can_ok 'main', $source, lcfirst $source;
    }
}

# inspector
{
    lives_ok { Provision::DSL::create_and_export_inspector_keywords('main') }
         'create_and_export_inspector_keywords lives';

    foreach my $inspector (qw(Always Never)) {
        can_ok 'main', $inspector;
    }
    
    is_deeply Always(), 
        ['Provision::DSL::Inspector::Always'],
        'inspector structure w/o args';

    is_deeply Always(foo => 'bar'),
        ['Provision::DSL::Inspector::Always', foo => 'bar'],
        'inspector structure w/ args';
}

# installer
{
    lives_ok { Provision::DSL::create_and_export_installer_keywords('main') }
         'create_and_export_installer_keywords lives';

    foreach my $installer (qw(Debug Null)) {
        can_ok 'main', $installer;
    }
    
    is_deeply Debug(), 
        ['Provision::DSL::Installer::Debug'],
        'installer structure w/o args';

    is_deeply Debug(foo => 42),
        ['Provision::DSL::Installer::Debug', foo => 42],
        'installer structure w/ args';
}

# # files
# {
#     is_deeply [ map { $_->basename } @{Files("$FindBin::Bin/../resources")} ],
#         [qw(file3.txt file1.txt file2.txt file.tt file.txt)],
#         'List of files is OK';
# }

# include
{
    trap { Include foobar, some => 'thing' };
    
    is $trap->exit, 1, 'calling include exists with code 1';
    like $trap->stderr, qr{You\sare\srunning}xms, 'stderr text OK';
}

# prevent error message in Provision::DSL::END{} from firing
# Provision::DSL::App->instance->is_running(1);

done_testing;
