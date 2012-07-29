use ok 'Provision::DSL::Entity::Dir';
use ok 'Provision::DSL::Entity::Rsync';
use ok 'Provision::DSL::Entity::User';
use ok 'Provision::DSL::Entity::Group';

my $app = Provision::DSL::App->new(
    entity_package_for => {
        Dir   => 'Provision::DSL::Entity::Dir',
        Rsync => 'Provision::DSL::Entity::Rsync',
        User  => 'Provision::DSL::Entity::User',
        Group => 'Provision::DSL::Entity::Group',
    },
);

{
    package Provision::DSL;

    no strict 'refs';
    $Provision::DSL::app = $app;
}

$app;
