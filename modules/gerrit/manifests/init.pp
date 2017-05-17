# Manifest to setup a Gerrit instance
class gerrit(
    $ipv4,
    $ipv6,
    $config,
    $host,
    $ipv4,
    $ipv6,
    $slave_hosts = [],
    $slave = false,
) {

    class { '::gerrit::jetty':
        host   => $host,
        slave  => $slave,
        config => $config,
    }

    class { '::gerrit::proxy':
        require     => Class['gerrit::jetty'],
        host        => $host,
        slave_hosts => $slave_hosts,
        slave       => $slave,
    }

    if !$slave {
        class { '::gerrit::crons':
            require => Class['gerrit::jetty'],
        }
    }
}
