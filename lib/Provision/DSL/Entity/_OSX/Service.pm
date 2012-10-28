package Provision::DSL::Entity::_OSX::Service;
use Moo;

extends 'Provision::DSL::Entity::Service';

my $LAUNCHCTL = '/bin/launchctl';

### Start-Zeit als '%c' man 3 strftime ausgeben
### ps -p 94114 -o lstart


sub _build_path {
    my $self = shift;
    
    warn "OVERLOADED build Path (Service)";
    
    ### TODO: non-root users have different paths!
    return "/Library/LaunchDaemons/${\$self->name}.plist";
}

# around is_ok => sub {
#     my ($orig, $self) = @_;
# 
#     return $self->_is_service_running
#         && $self->$orig();
# };
# 
# sub _is_service_running {
#     my $self = shift;
#     
#     $self->command_succeeds($LAUNCHCTL, list => $self->name)
# }
# 
# before create => sub {
#     my $self = shift;
# 
#     if ($self->_is_service_running) {
#         $self->run_command($LAUNCHCTL, stop => $self->name);
#     } else {
#         $self->run_command($LAUNCHCTL, load => '-w' => $self->path);
#     }
# };
# 
# before remove => sub {
#     my $self = shift;
# 
#     $self->run_command($LAUNCHCTL, unload => '-w' => $self->path);
# };

1;
