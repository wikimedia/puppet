# vim: set ts=4 et sw=4:

# TODO: now that other services inhabit service cluster A, move this definition in a
# better place
@monitoring::group { 'sca_eqiad': description => 'Service Cluster A servers' }

class role::mathoid{
    system::role { 'role::mathoid':
        description => 'mathoid server'
    }

    class { '::mathoid':
      require   => Package['mathoid/mathoid'],
    }

    package { 'mathoid/mathoid':
        provider => 'trebuchet',
    }

    group { 'mathoid':
      ensure => present,
      name   => 'mathoid',
      system => true,
    }

    user { 'mathoid':
      gid           => 'mathoid',
      home          => '/srv/deployment/mathoid/mathoid',
      managehome    => true,
      system        => true,
    }

    ferm::service { 'mathoid':
      proto => 'tcp',
      port  => '10042'
    }

    monitoring::service { 'mathoid':
      description => 'mathoid',
      check_command => 'check_http_on_port!10042',
    }
}

class role::mathoid::jenkins_access {
    # Allow ssh access from the Jenkins master to the server where mathoid is
    # running
    include contint::firewall::labs

    # Instance got to be a Jenkins slave so we can update mathoid whenever a
    # change is made on mediawiki/services/mathoid repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave-scripts
}
