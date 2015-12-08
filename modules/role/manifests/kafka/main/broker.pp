# == Class role::kafka::main::broker
# Sets up a broker belonging to a main Kafka cluster.
# This role works for any site.
#
# See modules/role/manifests/kafka/README.md for more information.
#
class role::kafka::main::broker {
    include role::kafka::main::config

    require_package('openjdk-7-jdk')

    system::role { 'role::kafka::main::broker':
        description => "Kafka Broker Server in the ${::role::kafka::main::config::cluster_name} cluster",
    }

    # Make these local so kafka-profile.sh.erb can easily render them.
    $zookeeper_url  = $::role::kafka::main::config::zookeeper_url
    $brokers_string = $::role::kafka::main::config::brokers_string
    # export ZOOKEEPER_URL and BROKER_LIST user environment variable.
    # This makes it much more convenient to run kafka commands without having
    # to specify the --zookeeper or --brokers flag every time.
    file { '/etc/profile.d/kafka.sh':
        owner   => 'root',
        mode    => '0444',
        content => template('role/kafka/kafka-profile.sh.erb'),
    }

    $log_dirs = $::realm ? {
        'labs'       => ['/var/spool/kafka'],
        # Production main Kafka brokers have more disks.
        'production' => [
            # TODO: fill this in with real partitions when we have hardware.
            '/var/spool/kafka/a/data',
            '/var/spool/kafka/b/data',
            '/var/spool/kafka/c/data',
            '/var/spool/kafka/d/data',
        ],
    }

    $nofiles_ulimit = $::realm ? {
        # Use default ulimit for labs kafka
        'labs'       => 8192,
        # Increase ulimit for production kafka.
        'production' => 65536,
    }

    class { '::kafka::server':
        log_dirs                        => $log_dirs,
        brokers                         => $::role::kafka::main::config::brokers_config,
        zookeeper_hosts                 => $::role::kafka::main::config::zookeeper_hosts,
        zookeeper_chroot                => $::role::kafka::main::config::zookeeper_chroot,
        nofiles_ulimit                  => $nofiles_ulimit,
        jmx_port                        => $::role::kafka::analytics::config::jmx_port,

        # Enable auto creation of topics.
        auto_create_topics_enable       => true,

        # (Temporarily?) disable auto leader rebalance.
        # I am having issues with analytics1012, and I can't
        # get Camus to consume properly for its preferred partitions
        # if it is online and the leader.  - otto
        auto_leader_rebalance_enable    => false,

        default_replication_factor      => min(3, size($::role::kafka::main::config::brokers_array)),
        # Start with a low number of (auto created) partitions per
        # topic.  This can be increased manually for high volume
        # topics if necessary.
        num_partitions                  => 1,

        # Use LinkedIn recommended settings with G1 garbage collector,
        jvm_performance_opts            => '-server -XX:PermSize=48m -XX:MaxPermSize=48m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35',
    }

    # firewall Kafka Broker
    ferm::service { 'kafka-broker':
        proto  => 'tcp',
        # TODO: A custom port can be configured in
        # $brokers_config.  Extract the proper
        # port to open from that config hash.
        port   => 9999,
        srange => '$ALL_NETWORKS',
    }

    # Include Kafka Server Jmxtrans class
    # to send Kafka Broker metrics to Ganglia and statsd.
    class { '::kafka::server::jmxtrans':
        ganglia  => hiera('ganglia_aggregators', undef),
        statsd   => hiera('statsd', undef),
        jmx_port => $::kafka::server::jmx_port,
        require  => Class['::kafka::server'],
    }

    # Monitor kafka in production
    if $::realm == 'production' {
        class { '::kafka::server::monitoring':
            jmx_port => $::role::kafka::analytics::config::jmx_port,
        }
    }
}
