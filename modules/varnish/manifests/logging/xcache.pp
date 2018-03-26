# == Define varnish::logging::xcache:
# Mtail program parsing X-Cache header and
# making hit-related stats available to Prometheus.
#
# === Parameters
#
# === Examples
#
#  varnish::logging::xcache {
#  }
#
define varnish::logging::xcache(
) {
    include ::varnish::common

    file { '/usr/local/bin/varnishxcache':
        ensure => absent,
        notify => Service['varnishxcache'],
    }

    systemd::service { 'varnishxcache':
        ensure  => absent,
        content => '',
    }

    nrpe::monitor_service { 'varnishxcache':
        ensure       => absent,
        description  => 'Varnish traffic logger - varnishxcache',
        nrpe_command => '/bin/true',
    }

    mtail::program { 'varnishxcache':
        source => 'puppet:///modules/mtail/programs/varnishxcache.mtail',
        notify => Service['varnishmtail'],
    }
}
