# == Class: diamond
#
# Diamond is a Python network daemon that collects system metrics and
# publishes them to a metric aggregator like Graphite or StatsD. Diamond
# ships with a suite of metric collectors for CPU, memory, network, disk,
# etc. Diamond also features an API for implementing custom collectors
# that gather metrics from almost any source.
#
# === Parameters
#
# [*handler*]
#   Import path and class name of diamond.handler.Handler subclass to
#   publish metrics too.
#
#   NOTE:
#      An empty handler string will purge all handlers
#
#   See: <https://github.com/BrightcoveOS/Diamond/wiki/Handlers>
#
# [*interval*]
#   Default interval in seconds at which statistics will be collected
#
# [*settings*]
#   A hash of configuration options for the desired handler.
#   See <https://github.com/BrightcoveOS/Diamond/wiki/Handlers>
#   for a listing of configuration options.
#
#   These are passed on verbatim to diamond so should all be quoted
#   strings and not native puppet types e.g. 'true' not true.
#
# [*path_prefix*]
#   The prefix to be used for metrics, used to namespace where
#   the metric came from.
#
# [*keep_logs_for*]
#   Integer of days to keep logs after current day.
#
# [*service*]
#   controls the state of the diamond service
#   See: http://docs.puppetlabs.com/references/latest/type.html#service-attribute-ensure
#
# === Examples
#
# A Graphite configuration for Diamond:
#
#  class { '::diamond':
#    handler  => 'diamond.handler.graphite.GraphiteHandler',
#    settings => {
#      host => 'graphite.wikimedia.org',
#      port => 2003,
#    },
#  }
#

class diamond(
    $handler       = 'diamond.handler.dastatsd.StatsHandler',
    $interval      = '60',
    $path_prefix   = 'servers',
    $keep_logs_for = '5',
    $service       = running,
    $settings      = {
        host => 'localhost',
        port => '8125',
    },
) {
    require_package('python-statsd')

    package { [ 'python-diamond', 'python-configobj' ]:
        ensure  => present,
    }

    file { [ '/etc/diamond/collectors', '/etc/diamond/handlers' ]:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['python-diamond'],
    }

    file { '/etc/diamond/diamond.conf':
        content => template('diamond/diamond.conf.erb'),
        require => File['/etc/diamond/collectors', '/etc/diamond/handlers'],
    }

    if !empty($handler) {
        # Truncate the import path, leaving only the class name.
        $handler_class = regsubst($handler, '.*\.', '')
        file { "/etc/diamond/handlers/${handler_class}.conf":
            content => template('diamond/handler.conf.erb'),
        }
    }

    service { 'diamond':
        ensure     => $service,
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['python-diamond'],
        subscribe  => File['/etc/diamond/diamond.conf'],
    }


    diamond::collector { 'CPU':
        settings => {
            # lint:ignore:quoted_booleans
            # As per comments above, these must be quoted for the config
            #  file.
            percore   => 'false',
            normalize => 'true',
            # lint:endignore
        },
    }

    diamond::collector { 'Network': }

    diamond::collector { 'TCP': }

    diamond::collector { 'DiskUsage':
        settings => {
            devices   => 'PhysicalDrive[0-9]+$|md[0-9]+$|sd[a-z]+$|x?vd[a-z]+$|disk[0-9]+$|dm-[0-9]+$',
        },
    }

    # Ensure non parsoid and parsoid varnish hosts do not have this collector.
    # Temporary hack, this will be removed once puppet has applied this.
    # If this is still here by 2015-10-23, please poke otto.
    # See: https://gerrit.wikimedia.org/r/#/c/246084/
    if ($::hostname !~ 'cp104[58]' and
        $::hostname !~ 'cp202[26]' and
        $::hostname !~ 'wtp10(0[1-9]|1[0-9]|2[0-4)|wtp20(0[1-9]|1[0-9]|2[0-4])') {

        diamond::collector { 'TcpConnStates':
            source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
            ensure => 'absent',
        }
    }
}
