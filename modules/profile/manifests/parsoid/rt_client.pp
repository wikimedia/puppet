# This instantiates testreduce::client
class profile::parsoid::rt_client(
    $parsoid_port = hiera('parsoid::testing::parsoid_port'),
    Stdlib::Ensure::Service $service_ensure = lookup('profile::parsoid::rt_client::service_ensure'),
){
    include ::testreduce

    testreduce::client { 'parsoid-rt-client':
        instance_name  => 'parsoid-rt-client',
        service_ensure => $service_ensure,
        parsoid_port   => $parsoid_port,
    }

    base::service_auto_restart { 'parsoid-rt-client': }
}
