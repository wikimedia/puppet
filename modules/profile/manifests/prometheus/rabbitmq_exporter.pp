class profile::prometheus::rabbitmq_exporter (
    $prometheus_nodes = hiera('profile::openstack::base::monitoring_host'),
) {
    $ferm_srange = "(@resolve((${prometheus_nodes})) @resolve((${prometheus_nodes}), AAAA))"

    require_package('prometheus-rabbitmq-exporter')

    service { 'prometheus-rabbitmq-exporter':
        ensure  => running,
        require => File['/etc/prometheus/rabbitmq-exporter.yaml'],
    }

    $rabbit_monitor_username = hiera('profile::openstack::base::rabbit_monitor_user') # lint:ignore:wmf_styleguide
    $rabbit_monitor_password = hiera('profile::openstack::base::rabbit_monitor_pass') # lint:ignore:wmf_styleguide
    $rabbit_host='localhost:15672'

    file { '/etc/prometheus/rabbitmq-exporter.yaml':
        ensure  => present,
        mode    => '0440',
        owner   => 'prometheus',
        group   => 'prometheus',
        content => template('profile/prometheus/rabbitmq-exporter.conf.erb'),
    }

    ferm::service { 'prometheus-rabbitmq-exporter':
        proto  => 'tcp',
        port   => '9195',
        srange => $ferm_srange,
    }
}
