# === Class profile::cache::base
#
# Sets up some common things for cache instances:
# - LVS/conftool
# - monitoring
# - logging/analytics
# - storage
#
class profile::cache::base(
    $cache_cluster = hiera('cache::cluster'),
    $statsd_host = hiera('statsd'),
    $zero_site = hiera('profile::cache::base::zero_site'),
    $purge_host_only_upload_re = hiera('profile::cache::base::purge_host_only_upload_re'),
    $purge_host_not_upload_re = hiera('profile::cache::base::purge_host_not_upload_re'),
    $storage_parts = hiera('profile::cache::base::purge_host_not_upload_re'),
) {
    # Needed profiles
    require ::profile::conftool::client
    require ::profile::cache::kafka::webrequest
    require ::role::prometheus::varnish_exporter
    require ::standard

    include ::lvs::configuration
    include ::network::constants

    class { 'conftool::scripts': }

    if $::realm == 'production' {
        # Only production needs system perf tweaks
        class { 'cacheproxy::performance': }

        # Periodic cron restarts, we need this to mitigate T145661
        class { 'cacheproxy::cron_restart':
            # lint:ignore:wmf_styleguide
            nodes => hiera("cache::${cache_cluster}::nodes")
            # lint:endignore
        }
    }

    # Not ideal factorization to put this here, but works for now
    class { 'varnish::zero_update':
        site         => $zero_site,
    }

    ###########################################################################
    # Analytics/Logging stuff
    ###########################################################################
    # Install a varnishkafka producer to send
    # varnish webrequest logs to Kafka.

    class { '::varnish::logging':
        cache_cluster => $cache_cluster,
        statsd_host   => $statsd_host,
    }

    ###########################################################################
    # auto-depool on shutdown + conditional one-shot auto-pool on start
    # note: we can't use 'service' because we don't want to 'ensure =>
    # stopped|running', and 'service_unit' with 'declare_service => false'
    # wouldn't enable the service in systemd terms, either.
    ###########################################################################

    $tp_unit_path = '/lib/systemd/system/traffic-pool.service'
    $varlib_path = '/var/lib/traffic-pool'

    file { $tp_unit_path:
        ensure => present,
        source => 'puppet:///modules/role/cache/traffic-pool.service',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
    }

    file { $varlib_path:
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    exec { 'systemd reload+enable for traffic-pool':
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload && /bin/systemctl enable traffic-pool',
        subscribe   => File[$tp_unit_path],
        require     => File[$varlib_path],
    }

    nrpe::monitor_systemd_unit_state { 'traffic-pool':
        require  => File[$tp_unit_path],
        critical => false, # promote to true once better-tested in the real world
    }


    ###########################################################################
    # Storage configuration
    ###########################################################################

    # everything from here down is related to backend storage/weight config

    $storage_size = $::hostname ? {
        /^cp1008$/              => 117, # Intel X-25M 160G (test host!)
        /^cp30(0[3-9]|10)$/     => 460, # Intel M320 600G via H710
        /^cp400[1234]$/         => 220, # Seagate ST9250610NS - 250G (only non-SSD left!)
        /^cp40(2[1-9]|3[0-2])$/ => 730, # Intel S3710 800G (new default 2017)
        /^cp[0-9]{4}$/          => 360, # Intel S3700 400G (old default pre-2017)
        default                 => 6,   # 6 is the bare min, for e.g. virtuals
    }

    $filesystems = unique($storage_parts)
    varnish::setup_filesystem { $filesystems: }
    Varnish::Setup_filesystem <| |> -> Varnish::Instance <| |>

    $file_storage_args = join([
        "-s main1=file,/srv/${storage_parts[0]}/varnish.main1,${storage_size}G",
        "-s main2=file,/srv/${storage_parts[1]}/varnish.main2,${storage_size}G",
    ], ' ')
}
