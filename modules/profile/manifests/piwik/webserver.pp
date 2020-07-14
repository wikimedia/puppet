# == Class: profile::piwik::webserver
#
# Apache webserver instance configured with mpm-prefork and mod_php.
# This configuration should be improved with something more up to date like
# mpm-event and php-fpm/hhmv.
# Piwik has been rebranded to 'Matomo', but to avoid too many changes
# we are going to just keep the previous name.
#
class profile::piwik::webserver(
    $prometheus_nodes = hiera('prometheus_nodes')
){
    include ::profile::prometheus::apache_exporter

    $php_module = 'php7.3'
    $php_ini = '/etc/php/7.3/apache2/php.ini'

    package { "${php_module}-mbstring":
        ensure => 'present',
    }
    package { "${php_module}-xml":
        ensure => 'present',
    }

    package { "libapache2-mod-${php_module}":
        ensure => 'present',
    }

    class { '::httpd':
        modules => ['headers', $php_module, 'rewrite'],
        require => Package["libapache2-mod-${php_module}"],
    }

    class { '::httpd::mpm':
        mpm    => 'prefork',
        source => 'puppet:///modules/profile/piwik/mpm_prefork.conf',
    }

    require ::profile::analytics::httpd::utils
    include profile::idp::client::httpd

    monitoring::service { 'piwik':
        description   => 'piwik.wikimedia.org',
        check_command => 'check_http_unauthorized!piwik.wikimedia.org!/',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Piwik',
    }

    file_line { 'enable_php_opcache':
        line   => 'opcache.enable=1',
        match  => '^;?opcache.enable\s*\=',
        path   => $php_ini,
        notify => Class['::httpd'],
    }

    file_line { 'php_memory_limit':
        line   => 'memory_limit = 256M',
        match  => '^;?memory_limit\s*\=',
        path   => $php_ini,
        notify => Class['::httpd'],
    }

    ferm::service { 'piwik_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}
