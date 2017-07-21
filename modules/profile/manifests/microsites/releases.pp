class profile::microsites::releases {
    include ::base::firewall

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }

    class { '::releases':
        sitename => 'releases.wikimedia.org',
    }

    class { '::releases::reprepro': }

    # ssh-based uploads from deployment servers
    ferm::rule { 'deployment_package_upload':
        ensure => present,
        rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
    }

    ferm::service { 'releases_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }

    rsync::quickdatacopy { 'srv-org-wikimedia-releases':
        ensure      => present,
        source_host => 'bromine.eqiad.wmnet',
        dest_host   => 'releases1001.eqiad.wmnet',
        module_path => '/srv/org/wikimedia/releases',
    }

    include ::profile::backup::host
    backup::set { 'srv-org-wikimedia': }
}
