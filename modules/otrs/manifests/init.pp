# vim: set ts=4 et sw=4:

class otrs {
    include otrs::mail
    include otrs::web

    $packages = [
        'libapache-dbi-perl',
        'libdbd-mysql-perl',
        'libgd-graph-perl',
        'libgd-text-perl',
        'libio-socket-ssl-perl',
        'libjson-xs-perl',
        'libnet-ldap-perl',
        'libpdf-api2-perl',
        'libsoap-lite-perl',
        'libtext-csv-xs-perl',
        'libtimedate-perl',
        'mysql-client',
        'perl-doc',
    ]

    package { $packages:
        ensure => 'present',
    }

    user { 'otrs':
        home       => '/var/lib/otrs',
        groups     => 'www-data',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    file { '/opt/otrs/Kernel/Config.pm':
        ensure  => 'file',
        owner   => 'otrs',
        group   => 'www-data',
        mode    => '0440',
        source  => template('otrs/Config.pm.erb'),
    }

    file { '/etc/cron.d/otrs':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/otrs/crontab.otrs',
    }

    file { '/opt/otrs/bin/otrs.TicketExport2Mbox.pl':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0755',
        source => 'puppet:///modules/otrs/otrs.TicketExport2Mbox.pl',
    }

    file { '/opt/otrs/bin/cgi-bin/idle_agent_report':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0755',
        source => 'puppet:///modules/otrs/idle_agent_report',
    }

    file { '/opt/otrs/var/httpd/htdocs/skins/Agent/default/img/icons/product.ico':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0664',
        source => 'puppet:///modules/otrs/wmf.ico',
    }

    file { '/opt/otrs/Kernel/Output/HTML/OTRS':
        ensure => link,
        target => '/opt/otrs/Kernel/Output/HTML/Standard',
    }
}
