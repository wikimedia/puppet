# == Class: openstack::keystone::monitor
# NRPE checks to make sure that the right keystone projects
#  exist and that projects have the proper service users.
#
# This also checks the functionality of the keystone API generally.

class openstack2::keystone::monitor() {

    monitoring::service { 'keystone-http-35357':
        description   => 'keystone admin endpoint',
        check_command => 'check_http_on_port!35357',
    }

    monitoring::service { 'keystone-http-5000': # v2 api is limited here
        description   => 'keystone public endoint',
        check_command => 'check_http_on_port!5000',
    }

    # Script to check all keystone projects for a given user and role
    file { '/usr/local/bin/check_keystone_roles.py':
        ensure => present,
        source => 'puppet:///modules/openstack/check_keystone_roles.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # Script to make sure that service projects e.g. 'admin' exists
    file { '/usr/local/bin/check_keystone_projects.py':
        ensure => present,
        source => 'puppet:///modules/openstack/check_keystone_projects.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # Make sure 'novaobserver' has 'observer' everywhere
    nrpe::monitor_service { 'check-novaobserver-membership':
        nrpe_command => '/usr/local/bin/check_keystone_roles.py novaobserver observer',
        description  => 'novaobserver has only observer role',
        require      => File['/usr/local/bin/check_keystone_roles.py'],
    }

    # Make sure 'novaadmin' has 'projectadmin' and 'user' everywhere
    nrpe::monitor_service { 'check-novaadmin-membership':
        nrpe_command => '/usr/local/bin/check_keystone_roles.py novaadmin user projectadmin',
        description  => 'novaadmin has roles in every project',
        require      => File['/usr/local/bin/check_keystone_roles.py'],
    }

    # Verify service projects
    nrpe::monitor_service { 'check-keystone-projects':
        nrpe_command => '/usr/local/bin/check_keystone_projects.py',
        description  => 'Keystone admin and observer projects exist',
        require      => File['/usr/local/bin/check_keystone_roles.py'],
    }
}
