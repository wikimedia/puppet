# == Class mailman3::web
#
# Installs the django web app serving mailman3 to users
class mailman3::web (
    Stdlib::Fqdn $host,
    Stdlib::Fqdn $db_host,
    String $db_name,
    String $db_user,
    String $db_password,
    String $api_password,
    String $secret,
    String $archiver_key,
    String $service_ensure = 'running',
) {

    ensure_packages([
        'python3-mysqldb',
        'dbconfig-mysql',
    ])

    package { 'mailman3-web':
        ensure => present,
    }

    file { '/etc/mailman3/mailman-web.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mailman3/mailman-web.py.erb'),
    }

    file { '/usr/local/bin/mailman-web':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/mailman3/mailman-web',
    }

    service { 'mailman3-web':
        ensure    => $service_ensure,
        hasstatus => false,
        pattern   => 'mailmanctl',
        subscribe => File['/etc/mailman3/mailman-web.py'],
    }
}
