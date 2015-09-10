class openstack::designate::service ($openstack_version=$::openstack::version, $designateconfig) {

    include openstack::repo

    include passwords::openstack::nova
    $ldap_user_pass = $passwords::openstack::nova::nova_ldap_user_pass

    package { ['python-designateclient',
                'designate-sink',
                'designate-common',
                'designate',
                'designate-api',
                'designate-doc',
                'designate-central',
                'python-nova-ldap',
                'python-novaclient',
                'python-paramiko',
                'python-nova-fixed-multi' ]:
        ensure  => present,
        require => Class['openstack::repo'];
    }

    service {'designate-api':
        ensure  => running,
        require => Package['designate-api'];
    }

    service {'designate-sink':
        ensure  => running,
        require => Package['designate-sink'];
    }

    service {'designate-central':
        ensure  => running,
        require => Package['designate-central'];
    }

    # In the perfect future when the designate packages set up
    #  an init script for this, some of this can be removed.
    base::service_unit { 'designate-pool-manager':
        ensure  =>  present,
        refresh =>  true,
        upstart =>  true,
        username => 'designate',
        require =>  Package['designate'],
    }

    # Likewise with mdns.
    base::service_unit { 'designate-mdns':
        ensure  =>  present,
        refresh =>  true,
        upstart =>  true,
        username => 'designate',
        require =>  Package['designate'],
    }

    # This password is to allow designate to write to instance metadata
    $wikitech_nova_ldap_user_pass = $passwords::openstack::nova::nova_ldap_user_pass

    file {
        '/etc/designate/designate.conf':
            content => template("openstack/${openstack_version}/designate/designate.conf.erb"),
            owner   => designate,
            group   => designate,
            notify  => Service['designate-api','designate-sink','designate-central'],
            require => Package['designate-common'],
            mode    => '0440';
        '/etc/designate/api-paste.ini':
            content => template("openstack/${$openstack_version}/designate/api-paste.ini.erb"),
            owner   => 'designate',
            group   => 'designate',
            notify  => Service['designate-api','designate-sink','designate-central'],
            require => Package['designate-api'],
            mode    => '0440';
        '/etc/designate/policy.json':
            source  => "puppet:///modules/openstack/${$openstack_version}/designate/policy.json",
            owner   => 'designate',
            group   => 'designate',
            notify  => Service['designate-api','designate-sink','designate-central'],
            require => Package['designate-common'],
            mode    => '0440';
        '/etc/designate/rootwrap.conf':
            source => "puppet:///modules/openstack/${$openstack_version}/designate/rootwrap.conf",
            owner   => 'root',
            group   => 'root',
            notify  => Service['designate-api','designate-sink','designate-central'],
            require => Package['designate-common'],
            mode    => '0440';
    }

    # include rootwrap.d entries
}


