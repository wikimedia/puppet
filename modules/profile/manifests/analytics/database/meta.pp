# == Class role::analytics_cluster::database::meta
#
# Installs a MySQL/MariaDB server for use with Hive and Oozie
# and other Analytics Cluster services.
#
class profile::analytics::database::meta(
    $datadir            = lookup('profile::analytics::database::meta::datadir', { 'default_value' => '/var/lib/mysql' }),
    $tmpdir             = lookup('profile::analytics::database::meta::tmpdir', { 'default_value' => '/srv/tmp' }),
    $monitoring_enabled = lookup('profile::analytics::database::meta::monitoring_enabled', { 'default_value' => false }),
    $ferm_srange        = lookup('profile::analytics::database::meta::ferm_srange', { 'default_value' => '$DOMAIN_NETWORKS' }),
    $innodb_pool_size   = lookup('profile::analytics::database::meta::innodb_pool_size', { 'default_value' => '4G'}),
) {

    # Some CDH database init scripts need Java to run.
    Class['profile::java'] -> Class['profile::analytics::database::meta']

    require profile::mariadb::packages_wmf
    $basedir = $profile::mariadb::packages_wmf::basedir
    include profile::mariadb::wmfmariadbpy

    $mariadb_socket = '/run/mysqld/mysqld.sock'

    class { 'mariadb::config':
        config           => 'profile/analytics/database/meta/analytics-meta.my.cnf.erb',
        socket           => $mariadb_socket,
        port             => 3306,
        datadir          => $datadir,
        tmpdir           => $tmpdir,
        basedir          => $basedir,
        ssl              => 'puppet-cert',
        read_only        => false,
        innodb_pool_size => $innodb_pool_size,
    }

    # If labs, automate mysql_install_db. Supported only for recent
    # Debian OS like Stretch.
    if $::realm == 'labs' {
        exec { 'analytics_meta_mysql_install_db':
            command => "${basedir}/scripts/mysql_install_db",
            cwd     => $basedir,
            creates => "${datadir}/ibdata1",
            require => Class['mariadb::config'],
            before  => Class['mariadb::service'],
        }
    }

    class { 'mariadb::service':
        ensure  => 'running',
        manage  => true,
        enable  => true,
        require => Class['mariadb::config'],
    }


    profile::prometheus::mysqld_exporter_instance {'analytics-meta':
        socket => $mariadb_socket,
    }

    # Allow access to this analytics mysql instance from analytics networks.
    # Allow also the Druid public cluster to use it as storage for daemons
    # like the coordinator. The Druid analytics cluster already uses it but it
    # is already included in the ANALYTICS_NETWORKS definition.
    ferm::service{ 'analytics-mysql-meta':
        proto  => 'tcp',
        port   => '3306',
        srange => $ferm_srange,
    }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
        nrpe::monitor_service { 'mysql_analytics-meta':
            description   => 'analytics-meta MySQL instance',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C mysqld',
            contact_group => 'admins,analytics',
            require       => Class['mariadb::service'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Mysql_Meta',
        }

        nrpe::monitor_service { 'mysql_analytics-meta_disk_space':
            description   => 'MySQL disk space for analytics-meta instance',
            nrpe_command  => '/usr/lib/nagios/plugins/check_disk -w 10g -c 5g -l -p /var/lib/mysql',
            contact_group => 'admins,analytics',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Mysql_Meta',
        }
    }
}
