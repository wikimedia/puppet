# This instantiates testreduce::client
class role::parsoid-rt-client {
    class {'::testreduce':
    }

    file { '/srv/testreduce/parsoid-rt-client.rttest.localsettings.js':
        source => 'puppet:///modules/testreduce/parsoid-rt-client.rttest.localsettings.js',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['parsoid-rt-client'],
    }

    testreduce::client { 'parsoid-rt-client':
        instance_name => 'parsoid-rt-client',
    }
}
