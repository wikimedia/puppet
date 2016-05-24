# == Class base::monitoring::host
# Sets up base Nagios monitoring for the host.  This includes
# - ping
# - ssh
# - dpkg
# - disk space
# - raid
#
# Note that this class is probably already included for your node
# by the class base.  If you want to change the contact_group, set
# the variable contactgroups in hiera.
# class base will use this variable as the $contact_group argument
# when it includes this class.
#
# == Parameters
# $contact_group            - Nagios contact_group to use for notifications. Defaults to
#                             admins
#
# nrpe_check_disk_options   - Default options for checking disks.  Defaults to checking
#                             all disks and warning at < 6% and critical at < 3% free.
#
# nrpe_check_disk_critical  - Make disk space alerts paging, defaults to not paging
#
# nrpe_check_disk_max_check_attempts - see: `nrpe::monitor_service:retries`
#
# nrpe_check_disk_warning_threshold  - see: `nrpe::check_disk::warning_threshold`
#
# nrpe_check_disk_critical_threshold - see: `nrpe::check_disk::critical_threshold`
#
# nrpe_check_disk_ignore             - see: `nrpe::check_disk::ignore_ereg_path`
# nrpe_check_disk_exclude_types      - see: `nrpe::check_disk::exclude_types`
# nrpe_check_disk_paths              - see: `nrpe::check_disk::paths`
class base::monitoring::host(
    $contact_group = hiera('contactgroups', 'admins'),
    # the -A -i ... part is a gross hack to workaround Varnish partitions
    # that are purposefully at 99%. Better ideas are welcome.
    $nrpe_check_disk_options = '-w 6% -c 3% -l -e -A -i "/srv/sd[a-b][1-3]" --exclude-type=tracefs',
    $nrpe_check_disk_critical = false,
    $nrpe_check_disk_max_check_attempts = 3,
    $nrpe_check_disk_warning_threshold = '6%',
    $nrpe_check_disk_critical_threshold = '3%',
    $nrpe_check_disk_ignore = [ '/srv/sd[a-b][1-3]' ],
    $nrpe_check_disk_exclude_types = [ 'tracefs' ],
    $nrpe_check_disk_paths = [],
) {
    include base::puppet::params # In order to be able to use some variables

    # RAID checks
    include raid

    monitoring::host { $::hostname: }

    monitoring::service { 'ssh':
        description   => 'SSH',
        check_command => 'check_ssh',
    }

    file { '/usr/local/lib/nagios/plugins/check_puppetrun':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/monitoring/check_puppetrun';
    }
    file { '/usr/local/lib/nagios/plugins/check_eth':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('base/check_eth.erb'),
    }
    file { '/usr/lib/nagios/plugins/check_sysctl':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/check_sysctl',
    }

    file { '/usr/lib/nagios/plugins/check-fresh-files-in-dir.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/monitoring/check-fresh-files-in-dir.py',
    }

    sudo::user { 'nagios_puppetrun':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check_puppetrun'],
    }

    # Check for disk usage on the root partition for labs instances
    # This is mapped to the monitoring template - ensure you update
    # labsnagiosbuilder/templates/classes/base.cfg under labs/nagios-builder
    # to reflect this check name
    if $::realm == 'labs' {
        nrpe::monitor_service { 'root_disk_space':
            description  => 'Disk space on /',
            nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 5% -c 2% -l -e -p /',
        }
    }

    nrpe::check_disk { 'default':
        critical         => $nrpe_check_disk_critical,
        ignore_ereg_path => $nrpe_check_disk_ignore,
        options          => $nrpe_check_disk_options,
        exclude_types    => [ 'tracefs' ],
        paths            => $nrpe_check_disk_paths,
    }

    nrpe::monitor_service { 'dpkg':
        description  => 'DPKG',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_dpkg',
    }
    $warninginterval = $base::puppet::params::freshnessinterval
    $criticalinterval = $base::puppet::params::freshnessinterval * 2
    nrpe::monitor_service { 'puppet_checkpuppetrun':
        description  => 'puppet last run',
        nrpe_command => "/usr/bin/sudo /usr/local/lib/nagios/plugins/check_puppetrun -w ${warninginterval} -c ${criticalinterval}",
    }
    nrpe::monitor_service { 'check_eth':
        description  => 'configured eth',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_eth',
    }
    nrpe::monitor_service { 'check_dhclient':
        description  => 'dhclient process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 0:0 -c 0:0 -C dhclient',
    }
    nrpe::monitor_service { 'check_salt_minion':
        description  => 'salt-minion processes',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1: -c 1:4 --ereg-argument-array '^/usr/bin/python /usr/bin/salt-minion'",
    }
}
