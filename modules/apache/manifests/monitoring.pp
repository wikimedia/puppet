# == Class: apache::monitoring
#
# Configures Apache to serve a server status page via mod_status
# at /server-status (exposed only to requests originating on the
# server), and provisions metric-gathering modules for Diamond
# and Ganglia.
#
class apache::monitoring {
    include ::apache::mod::status
    include ::ganglia

    diamond::collector { 'Httpd':
        settings => {
            path => "${cluster}.httpd",
            urls => "http://127.0.0.1/server-status?auto"
        }
    }

    file { '/usr/lib/ganglia/python_modules/apache_status.py':
        source  => 'puppet:///modules/apache/apache_status.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['ganglia-monitor'],
    }

    file { '/etc/ganglia/conf.d/apache_status.pyconf':
        source  => 'puppet:///modules/apache/apache_status.pyconf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/usr/lib/ganglia/python_modules/apache_status.py'],
        notify  => Service['gmond'],
    }
}
