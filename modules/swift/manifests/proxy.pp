# == Class swift::proxy
#
# [*wmf_filter_rewrite*]
#
# Enable rewriting suitable for Wikimedia thumbnailing infrastructure.
# (boolean), Default: true
#
class swift::proxy (
    $proxy_service_host,
    $accounts = $swift::params::accounts,
    $credentials = $swift::params::account_keys,
    $memcached_servers         = ['localhost:11211'],
    $statsd_host               = undef,
    $statsd_metric_prefix      = undef,
    $statsd_sample_rate_factor = '1',
    $bind_port                 = '80',
    $num_workers               = $::processorcount,
    $backend_url_format        = 'sitelang',
    $shard_container_list      = undef,
    $rewrite_account           = undef,
    $rewrite_thumb_server      = undef,
    $dispersion_account        = undef,
    $tld                       = 'org',
    $thumborhost               = '',
    $thumbor_wiki_list         = [],
    $wmf_filter_rewrite        = true,
) {
    package {[
        'swift-proxy',
        'python-webob',
    ]:
        ensure => present,
    }

    file { '/etc/swift/proxy-server.conf':
        owner   => 'swift',
        group   => 'swift',
        mode    => '0440',
        content => template('swift/proxy-server.conf.erb'),
        require => Package['swift-proxy'],
    }

    if $dispersion_account != undef {
        file { '/etc/swift/dispersion.conf':
            owner   => 'swift',
            group   => 'swift',
            mode    => '0440',
            content => template('swift/dispersion.conf.erb'),
            require => Package['swift'],
        }
    }

    logrotate::conf { 'swift-proxy':
        ensure => absent,
    }

    rsyslog::conf { 'swift-proxy':
        ensure   => absent,
    }

    # stock Debian package uses start-stop-daemon --chuid and init.d script to
    # start swift-proxy, our proxy binds to port 80 so it isn't going to work.
    # Use a modified version of 'swift-proxy' systemd unit from jessie-backports.
    if os_version('debian >= jessie') {
        base::service_unit { 'swift-proxy':
            systemd => true,
            refresh => false,
        }
    }

    file { '/usr/local/lib/python2.7/dist-packages/wmf/':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/swift/SwiftMedia/wmf/',
        recurse => 'remote',
    }
}
