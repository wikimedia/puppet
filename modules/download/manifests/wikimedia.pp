class download::wikimedia {

    system::role { 'download::wikimedia': description => 'download.wikimedia.org' }

    package { 'lighttpd':
        ensure => latest;
    }

    file { '/etc/lighttpd/lighttpd.conf':
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        path   => '/etc/lighttpd/lighttpd.conf',
        source => 'puppet:///files/download/lighttpd.conf';
    }

    service { 'lighttpd':
        ensure => running;
    }

    package { 'nfs-kernel-server':
        ensure => present;
    }

    file { '/etc/exports':
        require => Package[nfs-kernel-server],
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///files/download/exports',
    }

    service { 'nfs-kernel-server':
        require => [ Package[nfs-kernel-server], File['/etc/exports'] ],
    }

    package { 'gnupg':
        ensure => latest;
    }

    include generic::higher_min_free_kbytes

    monitor_service { 'lighttpd http':
        description   => 'Lighttpd HTTP',
        check_command => 'check_http',
    }

    monitor_service { 'nfs':
        description   => 'NFS',
        check_command => 'check_tcp!2049',
    }

}

