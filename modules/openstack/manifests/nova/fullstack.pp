# [*password*]
#  password for fullstack test user (same across backends)
#
# [*interval*]
#  seconds between fullstack test runs

class openstack::nova::fullstack(
    $password,
    $interval = 300,
    ) {

    group { 'osstackcanary':
        ensure => present,
        name   => 'osstackcanary',
    }

    user { 'osstackcanary':
        ensure     => present,
        gid        => 'osstackcanary',
        shell      => '/bin/false',
        home       => '/var/lib/osstackcanary',
        managehome => true,
        system     => true,
        require    => Group['osstackcanary'],
    }

    file { '/usr/local/sbin/nova-fullstack':
        ensure => present,
        mode   => '0755',
        owner  => 'osstackcanary',
        group  => 'osstackcanary',
        source => 'puppet:///modules/openstack/nova_fullstack_test.py',
    }

    $keyfile = '/var/lib/osstackcanary/osstackcanary_id'
    file { $keyfile:
        ensure  => present,
        mode    => '0600',
        owner   => 'osstackcanary',
        group   => 'osstackcanary',
        content => secret('nova/osstackcanary'),
    }

    file { '/etc/init/nova-fullstack.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        content => template('openstack/initscripts/nova-fullstack.upstart.erb'),
    }

    base::service_unit { 'nova-fullstack':
        ensure    => present,
        upstart   => true,
        subscribe => File['/etc/init/nova-fullstack.conf'],
    }
}
