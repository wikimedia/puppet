class ganglia::monitor::aggregator($sites) {
    require ganglia::monitor::packages
    include ganglia::configuration

    system::role { 'ganglia::monitor::aggregator': description => 'central Ganglia aggregator' }

    file { '/etc/ganglia/aggregators':
        ensure => directory,
        mode   => '0555',
    }

    file { '/etc/init/ganglia-monitor-aggregator.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "puppet:///modules/${module_name}/upstart/ganglia-monitor-aggregator.conf",
        before => Service['ganglia-monitor-aggregator'],
    }

    file { '/etc/init/ganglia-monitor-aggregator-instance.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "puppet:///modules/${module_name}/upstart/ganglia-monitor-aggregator-instance.conf",
        before => Service['ganglia-monitor-aggregator'],
    }

    define site_instances() {
        # Instantiate aggregators for all clusters for this site ($title)
        $cluster_list = suffix(keys($ganglia::configuration::clusters), "_${title}")
        instance { $cluster_list:
            monitored_site => $title
        }
    }

    site_instances{ $sites: }

    # when using upstart each instance is a separate service spawned
    # from a template in instance.pp, this was the old service used with upstart
    if $::initsystem = 'upstart'{
        service { 'ganglia-monitor-aggregator':
            ensure   => running,
            provider => upstart,
            name     => 'ganglia-monitor-aggregator',
        }
    }
}
